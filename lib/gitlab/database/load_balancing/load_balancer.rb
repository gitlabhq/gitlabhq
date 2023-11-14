# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Load balancing for ActiveRecord connections.
      #
      # Each host in the load balancer uses the same credentials as the primary
      # database.
      class LoadBalancer
        ANY_CAUGHT_UP  = :any
        ALL_CAUGHT_UP  = :all
        NONE_CAUGHT_UP = :none

        CACHE_KEY = :gitlab_load_balancer_host

        REPLICA_SUFFIX = '_replica'

        attr_accessor :service_discovery

        attr_reader :host_list, :configuration

        # configuration - An instance of `LoadBalancing::Configuration` that
        #                 contains the configuration details (such as the hosts)
        #                 for this load balancer.
        def initialize(configuration)
          @configuration = configuration
          @primary_only = !configuration.load_balancing_enabled?
          @host_list =
            if @primary_only
              HostList.new([PrimaryHost.new(self)])
            else
              HostList.new(configuration.hosts.map { |addr| Host.new(addr, self) })
            end
        end

        def name
          @configuration.db_config_name
        end

        def primary_only?
          @primary_only
        end

        def disconnect!(timeout: 120)
          host_list.hosts.each { |host| host.disconnect!(timeout: timeout) }
        end

        # Yields a connection that can be used for reads.
        #
        # If no secondaries were available this method will use the primary
        # instead.
        def read(&block)
          raise_if_concurrent_ruby!

          service_discovery&.log_refresh_thread_interruption

          conflict_retried = 0

          while host
            ensure_caching!

            begin
              connection = host.connection
              return yield connection
            rescue StandardError => error
              if primary_only?
                # If we only have primary configured, retrying is pointless
                raise error
              elsif serialization_failure?(error)
                # This error can occur when a query conflicts. See
                # https://www.postgresql.org/docs/current/static/hot-standby.html#HOT-STANDBY-CONFLICT
                # for more information.
                #
                # In this event we'll cycle through the secondaries at most 3
                # times before using the primary instead.
                will_retry = conflict_retried < @host_list.length * 3

                ::Gitlab::Database::LoadBalancing::Logger.warn(
                  event: :host_query_conflict,
                  message: 'Query conflict on host',
                  conflict_retried: conflict_retried,
                  will_retry: will_retry,
                  db_host: host.host,
                  db_port: host.port,
                  host_list_length: @host_list.length
                )

                if will_retry
                  conflict_retried += 1
                  release_host
                else
                  break
                end
              elsif connection_error?(error)
                host.offline!
                release_host
              else
                raise error
              end
            end
          end

          ::Gitlab::Database::LoadBalancing::Logger.warn(
            event: :no_secondaries_available,
            message: 'No secondaries were available, using primary instead',
            conflict_retried: conflict_retried,
            host_list_length: @host_list.length
          )

          read_write(&block)
        end

        # Yields a connection that can be used for both reads and writes.
        def read_write
          raise_if_concurrent_ruby!

          service_discovery&.log_refresh_thread_interruption

          connection = nil
          transaction_open = nil

          # Retry only once when in a transaction (see https://gitlab.com/gitlab-org/gitlab/-/issues/220242)
          attempts = pool.connection.transaction_open? ? 1 : 3

          # In the event of a failover the primary may be briefly unavailable.
          # Instead of immediately grinding to a halt we'll retry the operation
          # a few times.
          # It is not possible preserve transaction state during a retry, so we do not retry in that case.
          retry_with_backoff(attempts: attempts) do |attempt|
            connection = pool.connection
            transaction_open = connection.transaction_open?

            if attempt && attempt > 1
              ::Gitlab::Database::LoadBalancing::Logger.warn(
                event: :read_write_retry,
                message: 'A read_write block was retried because of connection error'
              )
            end

            yield connection
          rescue StandardError => e
            # No leaking will happen on the final attempt. Leaks are caused by subsequent retries
            not_final_attempt = attempt && attempt < attempts
            if transaction_open && connection_error?(e) && not_final_attempt
              ::Gitlab::Database::LoadBalancing::Logger.warn(
                event: :transaction_leak,
                message: 'A write transaction has leaked during database fail-over'
              )
            end

            raise e
          end
        end

        # Returns a host to use for queries.
        #
        # Hosts are scoped per thread so that multiple threads don't
        # accidentally re-use the same host + connection.
        def host
          request_cache[CACHE_KEY] ||= @host_list.next
        end

        # Releases the host and connection for the current thread.
        def release_host
          if host = request_cache[CACHE_KEY]
            host.disable_query_cache!
            host.release_connection
          end

          request_cache.delete(CACHE_KEY)
        end

        def release_primary_connection
          pool.release_connection
        end

        # Returns the transaction write location of the primary.
        def primary_write_location
          location = read_write do |connection|
            get_write_location(connection)
          end

          return location if location

          raise 'Failed to determine the write location of the primary database'
        end

        # Finds any up to date replica for the given LSN location and stores an up to date replica in the
        # SafeRequestStore to be used later for read-only queries. It returns a symbol to indicate if :any, :all or
        # :none were found to be caught up.
        def select_up_to_date_host(location)
          all_hosts = @host_list.hosts.shuffle
          first_caught_up_host = nil

          # We must loop through all of them so that we know if all are caught up. Some callers only care about finding
          # one caught up host and storing it in request_cache. But Sticking needs to know if ALL_CAUGHT_UP so that it
          # can clear the LSN position from Redis and not ask again in future.
          results = all_hosts.map do |host|
            caught_up = host.caught_up?(location)
            first_caught_up_host ||= host if caught_up
            caught_up
          end

          ActiveSupport::Notifications.instrument(
            'caught_up_replica_pick.load_balancing',
            { result: first_caught_up_host.present? }
          )

          return NONE_CAUGHT_UP unless first_caught_up_host

          request_cache[CACHE_KEY] = first_caught_up_host

          results.all? ? ALL_CAUGHT_UP : ANY_CAUGHT_UP
        end

        # Yields a block, retrying it upon error using an exponential backoff.
        def retry_with_backoff(attempts: 3, time: 2)
          # In CI we only use the primary, but databases may not always be
          # available (or take a few seconds to become available). Retrying in
          # this case can slow down CI jobs. In addition, retrying with _only_
          # a primary being present isn't all that helpful.
          #
          # To prevent this from happening, we don't make any attempt at
          # retrying unless one or more replicas are used. This matches the
          # behaviour from before we enabled load balancing code even if no
          # replicas were configured.
          return yield if primary_only?

          attempt = 1
          last_error = nil

          while attempt <= attempts
            begin
              return yield attempt # Yield the current attempt count
            rescue StandardError => error
              raise error unless connection_error?(error)

              # We need to release the primary connection as otherwise Rails
              # will keep raising errors when using the connection.
              release_primary_connection

              last_error = error
              sleep(time)
              attempt += 1
              time **= 2
            end
          end

          raise last_error
        end

        def connection_error?(error)
          case error
          when ActiveRecord::NoDatabaseError
            # Retrying this error isn't going to magically make the database
            # appear. It also slows down CI jobs that are meant to create the
            # database in the first place.
            false
          when ActiveRecord::StatementInvalid, ActionView::Template::Error
            # After connecting to the DB Rails will wrap query errors using this
            # class.
            if (cause = error.cause)
              connection_error?(cause)
            else
              false
            end
          when *CONNECTION_ERRORS
            true
          else
            # When PG tries to set the client encoding but fails due to a
            # connection error it will raise a PG::Error instance. Catching that
            # would catch all errors (even those we don't want), so instead we
            # check for the message of the error.
            error.message.start_with?('invalid encoding name:')
          end
        end

        def serialization_failure?(error)
          if error.cause
            serialization_failure?(error.cause)
          else
            error.is_a?(PG::TRSerializationFailure)
          end
        end

        # pool_size - The size of the DB pool.
        # host - An optional host name to use instead of the default one.
        # port - An optional port to connect to.
        def create_replica_connection_pool(pool_size, host = nil, port = nil)
          db_config = @configuration.db_config

          env_config = db_config.configuration_hash.dup
          env_config[:pool] = pool_size
          env_config[:host] = host if host
          env_config[:port] = port if port

          db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
            db_config.env_name,
            db_config.name + REPLICA_SUFFIX,
            env_config
          )

          # We cannot use ActiveRecord::Base.connection_handler.establish_connection
          # as it will rewrite ActiveRecord::Base.connection
          ActiveRecord::ConnectionAdapters::ConnectionHandler
            .new
            .establish_connection(db_config)
        end

        # ActiveRecord::ConnectionAdapters::ConnectionHandler handles fetching,
        # and caching for connections pools for each "connection", so we
        # leverage that.
        # rubocop:disable Database/MultipleDatabases
        def pool
          ActiveRecord::Base.connection_handler.retrieve_connection_pool(
            @configuration.connection_specification_name,
            role: ActiveRecord.writing_role,
            shard: ActiveRecord::Base.default_shard
          ) || raise(::ActiveRecord::ConnectionNotEstablished)
        end
        # rubocop:enable Database/MultipleDatabases

        def wal_diff(location1, location2)
          read_write do |connection|
            lsn1 = connection.quote(location1)
            lsn2 = connection.quote(location2)

            query = <<-SQL.squish
            SELECT pg_wal_lsn_diff(#{lsn1}, #{lsn2})
              AS result
            SQL

            row = connection.select_all(query).first
            row['result'] if row
          end
        end

        private

        def ensure_caching!
          return unless Rails.application.executor.active?
          return if host.query_cache_enabled

          host.enable_query_cache!
        end

        def request_cache
          base = SafeRequestStore[:gitlab_load_balancer] ||= {}
          base[self] ||= {}
        end

        # @param [ActiveRecord::Connection] ar_connection
        # @return [String]
        def get_write_location(ar_connection)
          use_new_load_balancer_query = Gitlab::Utils
            .to_boolean(ENV['USE_NEW_LOAD_BALANCER_QUERY'], default: true)

          sql =
            if use_new_load_balancer_query
              <<~NEWSQL
                SELECT CASE
                    WHEN pg_is_in_recovery() = true AND EXISTS (SELECT 1 FROM pg_stat_get_wal_senders())
                      THEN pg_last_wal_replay_lsn()::text
                    WHEN pg_is_in_recovery() = false
                      THEN pg_current_wal_insert_lsn()::text
                      ELSE NULL
                    END AS location;
              NEWSQL
            else
              <<~SQL
                SELECT pg_current_wal_insert_lsn()::text AS location
              SQL
            end

          row = ar_connection.select_all(sql).first
          row['location'] if row
        end

        def raise_if_concurrent_ruby!
          Gitlab::Utils.raise_if_concurrent_ruby!(:db)
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end
      end
    end
  end
end

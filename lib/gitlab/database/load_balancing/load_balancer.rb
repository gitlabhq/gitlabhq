# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Load balancing for ActiveRecord connections.
      #
      # Each host in the load balancer uses the same credentials as the primary
      # database.
      class LoadBalancer
        CACHE_KEY = :gitlab_load_balancer_host

        REPLICA_SUFFIX = '_replica'

        attr_reader :host_list

        # hosts - The hostnames/addresses of the additional databases.
        def initialize(hosts = [], model = ActiveRecord::Base)
          @model = model
          @host_list = HostList.new(hosts.map { |addr| Host.new(addr, self) })
        end

        def disconnect!(timeout: 120)
          host_list.hosts.each { |host| host.disconnect!(timeout: timeout) }
        end

        # Yields a connection that can be used for reads.
        #
        # If no secondaries were available this method will use the primary
        # instead.
        def read(&block)
          conflict_retried = 0

          while host
            ensure_caching!

            begin
              connection = host.connection
              return yield connection
            rescue StandardError => error
              if serialization_failure?(error)
                # This error can occur when a query conflicts. See
                # https://www.postgresql.org/docs/current/static/hot-standby.html#HOT-STANDBY-CONFLICT
                # for more information.
                #
                # In this event we'll cycle through the secondaries at most 3
                # times before using the primary instead.
                will_retry = conflict_retried < @host_list.length * 3

                LoadBalancing::Logger.warn(
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

          LoadBalancing::Logger.warn(
            event: :no_secondaries_available,
            message: 'No secondaries were available, using primary instead',
            conflict_retried: conflict_retried,
            host_list_length: @host_list.length
          )

          read_write(&block)
        end

        # Yields a connection that can be used for both reads and writes.
        def read_write
          connection = nil
          # In the event of a failover the primary may be briefly unavailable.
          # Instead of immediately grinding to a halt we'll retry the operation
          # a few times.
          retry_with_backoff do
            connection = pool.connection
            yield connection
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
            ::Gitlab::Database.main.get_write_location(connection)
          end

          return location if location

          raise 'Failed to determine the write location of the primary database'
        end

        # Returns true if there was at least one host that has caught up with the given transaction.
        def select_up_to_date_host(location)
          all_hosts = @host_list.hosts.shuffle
          host = all_hosts.find { |host| host.caught_up?(location) }

          return false unless host

          request_cache[CACHE_KEY] = host

          true
        end

        # Yields a block, retrying it upon error using an exponential backoff.
        def retry_with_backoff(retries = 3, time = 2)
          retried = 0
          last_error = nil

          while retried < retries
            begin
              return yield
            rescue StandardError => error
              raise error unless connection_error?(error)

              # We need to release the primary connection as otherwise Rails
              # will keep raising errors when using the connection.
              release_primary_connection

              last_error = error
              sleep(time)
              retried += 1
              time **= 2
            end
          end

          raise last_error
        end

        def connection_error?(error)
          case error
          when ActiveRecord::StatementInvalid, ActionView::Template::Error
            # After connecting to the DB Rails will wrap query errors using this
            # class.
            connection_error?(error.cause)
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
          db_config = pool.db_config

          env_config = db_config.configuration_hash.dup
          env_config[:pool] = pool_size
          env_config[:host] = host if host
          env_config[:port] = port if port

          replica_db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
            db_config.env_name,
            db_config.name + REPLICA_SUFFIX,
            env_config
          )

          # We cannot use ActiveRecord::Base.connection_handler.establish_connection
          # as it will rewrite ActiveRecord::Base.connection
          ActiveRecord::ConnectionAdapters::ConnectionHandler
            .new
            .establish_connection(replica_db_config)
        end

        private

        # ActiveRecord::ConnectionAdapters::ConnectionHandler handles fetching,
        # and caching for connections pools for each "connection", so we
        # leverage that.
        def pool
          ActiveRecord::Base.connection_handler.retrieve_connection_pool(
            @model.connection_specification_name,
            role: ActiveRecord::Base.writing_role,
            shard: ActiveRecord::Base.default_shard
          )
        end

        def ensure_caching!
          host.enable_query_cache! unless host.query_cache_enabled
        end

        def request_cache
          base = RequestStore[:gitlab_load_balancer] ||= {}
          base[pool] ||= {}
        end
      end
    end
  end
end

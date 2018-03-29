module Gitlab
  module Database
    module LoadBalancing
      # Load balancing for ActiveRecord connections.
      #
      # Each host in the load balancer uses the same credentials as the primary
      # database.
      #
      # This class *requires* that `ActiveRecord::Base.retrieve_connection`
      # always returns a connection to the primary.
      class LoadBalancer
        CACHE_KEY = :gitlab_load_balancer_host

        attr_reader :host_list

        # hosts - The hostnames/addresses of the additional databases.
        def initialize(hosts = [])
          @host_list = HostList.new(hosts.map { |addr| Host.new(addr, self) })
        end

        # Yields a connection that can be used for reads.
        #
        # If no secondaries were available this method will use the primary
        # instead.
        def read(&block)
          conflict_retried = 0

          while host
            begin
              return yield host.connection
            rescue => error
              if serialization_failure?(error)
                # This error can occur when a query conflicts. See
                # https://www.postgresql.org/docs/current/static/hot-standby.html#HOT-STANDBY-CONFLICT
                # for more information.
                #
                # In this event we'll cycle through the secondaries at most 3
                # times before using the primary instead.
                if conflict_retried < @host_list.length * 3
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

          LoadBalancing
            .log(:warn, 'No secondaries were available, using primary instead')

          read_write(&block)
        end

        # Yields a connection that can be used for both reads and writes.
        def read_write
          # In the event of a failover the primary may be briefly unavailable.
          # Instead of immediately grinding to a halt we'll retry the operation
          # a few times.
          retry_with_backoff do
            yield ActiveRecord::Base.retrieve_connection
          end
        end

        # Returns a host to use for queries.
        #
        # Hosts are scoped per thread so that multiple threads don't
        # accidentally re-use the same host + connection.
        def host
          RequestStore[CACHE_KEY] ||= @host_list.next
        end

        # Releases the host and connection for the current thread.
        def release_host
          RequestStore[CACHE_KEY]&.release_connection
          RequestStore.delete(CACHE_KEY)
        end

        def release_primary_connection
          ActiveRecord::Base.connection_pool.release_connection
        end

        # Returns the transaction write location of the primary.
        def primary_write_location
          read_write do |connection|
            row = connection
              .select_all("SELECT #{Gitlab::Database.pg_current_wal_insert_lsn}()::text AS location")
              .first

            if row
              row['location']
            else
              raise 'Failed to determine the write location of the primary database'
            end
          end
        end

        # Returns true if all hosts have caught up to the given transaction
        # write location.
        def all_caught_up?(location)
          @host_list.hosts.all? { |host| host.caught_up?(location) }
        end

        # Yields a block, retrying it upon error using an exponential backoff.
        def retry_with_backoff(retries = 3, time = 2)
          retried = 0
          last_error = nil

          while retried < retries
            begin
              return yield
            rescue => error
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
            connection_error?(error.original_exception)
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
          if error.respond_to?(:original_exception)
            serialization_failure?(error.original_exception)
          else
            error.is_a?(PG::TRSerializationFailure)
          end
        end
      end
    end
  end
end

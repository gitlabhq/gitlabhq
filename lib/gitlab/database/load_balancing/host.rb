module Gitlab
  module Database
    module LoadBalancing
      # A single database host used for load balancing.
      class Host
        attr_reader :pool

        delegate :connection, :release_connection, to: :pool

        # host - The address of the database.
        def initialize(host)
          @host = host
          @pool = Database.create_connection_pool(LoadBalancing.pool_size, host)
          @online = true
        end

        def offline!
          LoadBalancing.log(:warn, "Marking host #{@host} as offline")

          @online = false
          @pool.disconnect!
        end

        # Returns true if the host is online.
        def online?
          return true if @online

          begin
            retried = 0
            @online = begin
                        connection.active?
                      rescue
                        if retried < 3
                          release_connection
                          retried += 1
                          retry
                        else
                          false
                        end
                      end

            LoadBalancing.log(:info, "Host #{@host} came back online") if @online

            @online
          ensure
            release_connection
          end
        end

        # Returns true if this host has caught up to the given transaction
        # write location.
        #
        # location - The transaction write location as reported by a primary.
        def caught_up?(location)
          string = connection.quote(location)

          # In case the host is a primary pg_last_xlog_replay_location() returns
          # NULL. The recovery check ensures we treat the host as up-to-date in
          # such a case.
          query = "SELECT NOT pg_is_in_recovery() OR " \
            "pg_xlog_location_diff(pg_last_xlog_replay_location(), #{string}) >= 0 AS result"

          row = connection.select_all(query).first

          row && row['result'] == 't'
        ensure
          release_connection
        end
      end
    end
  end
end

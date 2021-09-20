# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # A host that wraps the primary database connection.
      #
      # This class is used to always enable load balancing as if replicas exist,
      # without the need for extra database connections. This ensures that code
      # using the load balancer doesn't have to handle the case where load
      # balancing is enabled, but no replicas have been configured (= the
      # default case).
      class PrimaryHost
        def initialize(load_balancer)
          @load_balancer = load_balancer
        end

        def release_connection
          # no-op as releasing primary connections isn't needed.
          nil
        end

        def enable_query_cache!
          # This could mess up the primary connection, so we make this a no-op
          nil
        end

        def disable_query_cache!
          # This could mess up the primary connection, so we make this a no-op
          nil
        end

        def query_cache_enabled
          @load_balancer.pool.query_cache_enabled
        end

        def connection
          @load_balancer.pool.connection
        end

        def disconnect!(timeout: 120)
          nil
        end

        def offline!
          nil
        end

        def online?
          true
        end

        def primary_write_location
          @load_balancer.primary_write_location
        end

        def database_replica_location
          row = query_and_release(<<-SQL.squish)
            SELECT pg_last_wal_replay_lsn()::text AS location
          SQL

          row['location'] if row.any?
        rescue *Host::CONNECTION_ERRORS
          nil
        end

        def caught_up?(_location)
          true
        end

        def query_and_release(sql)
          connection.select_all(sql).first || {}
        rescue StandardError
          {}
        ensure
          release_connection
        end
      end
    end
  end
end

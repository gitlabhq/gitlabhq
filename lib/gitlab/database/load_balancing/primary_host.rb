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
        WAL_ERROR_MESSAGE = <<~MSG.strip
          Obtaining WAL information when not using any replicas results in
          redundant queries, and may break installations that don't support
          streaming replication (e.g. AWS' Aurora database).
        MSG

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
          ::Gitlab::Database::LoadBalancing::Logger.warn(
            event: :host_offline,
            message: 'Marking primary host as offline'
          )

          nil
        end

        def online?
          true
        end

        def primary_write_location
          raise NotImplementedError, WAL_ERROR_MESSAGE
        end

        def database_replica_location
          raise NotImplementedError, WAL_ERROR_MESSAGE
        end

        def caught_up?(_location)
          true
        end
      end
    end
  end
end

module Geo
  module Scheduler
    module Secondary
      class PerShardSchedulerWorker < Geo::Scheduler::PerShardSchedulerWorker
        def perform
          return unless Gitlab::Geo.geo_database_configured?
          return unless Gitlab::Geo.secondary?

          super
        end

        def eligible_shards
          selective_sync_filter(healthy_shards)
        end

        def selective_sync_filter(shards)
          return shards unless ::Gitlab::Geo.current_node&.selective_sync_by_shards?

          shards & ::Gitlab::Geo.current_node.selective_sync_shards
        end
      end
    end
  end
end

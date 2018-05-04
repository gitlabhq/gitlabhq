module Geo
  module Scheduler
    class PerShardSchedulerWorker
      include ApplicationWorker
      include CronjobQueue
      include ::Gitlab::Utils::StrongMemoize
      include ::Gitlab::Geo::LogHelpers

      HEALTHY_SHARD_CHECKS = [
        Gitlab::HealthChecks::FsShardsCheck,
        Gitlab::HealthChecks::GitalyCheck
      ].freeze

      def perform
        Gitlab::Geo::ShardHealthCache.update(eligible_shard_names)

        eligible_shard_names.each { |shard_name| schedule_job(shard_name) }
      end

      def eligible_shard_names
        healthy_shard_names
      end

      def schedule_job(shard_name)
        raise NotImplementedError
      end

      def healthy_shard_names
        strong_memoize(:healthy_shard_names) do
          # For now, we need to perform both Gitaly and direct filesystem checks to ensure
          # the shard is healthy. We take the intersection of the successful checks
          # as the healthy shards.
          healthy_ready_shards.map { |result| result.labels[:shard] }.compact.uniq
        end
      end

      def ready_shards
        HEALTHY_SHARD_CHECKS.map(&:readiness)
      end

      def healthy_ready_shards
        ready_shards.map { |result| result.select(&:success) }.inject(:&)
      end
    end
  end
end

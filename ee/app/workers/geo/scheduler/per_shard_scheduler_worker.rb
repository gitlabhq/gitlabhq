module Geo
  module Scheduler
    class PerShardSchedulerWorker
      include ApplicationWorker
      include CronjobQueue
      include ::Gitlab::Utils::StrongMemoize

      HEALTHY_SHARD_CHECKS = [
        Gitlab::HealthChecks::FsShardsCheck,
        Gitlab::HealthChecks::GitalyCheck
      ].freeze

      def perform
        Gitlab::Geo::ShardHealthCache.update(eligible_shards)

        eligible_shards.each do |shard_name|
          schedule_job(shard_name)
        end
      end

      def schedule_job(shard_name)
        raise NotImplementedError
      end

      def eligible_shards
        healthy_shards
      end

      def healthy_shards
        strong_memoize(:healthy_shards) do
          # For now, we need to perform both Gitaly and direct filesystem checks to ensure
          # the shard is healthy. We take the intersection of the successful checks
          # as the healthy shards.
          HEALTHY_SHARD_CHECKS.map(&:readiness)
            .map { |check_result| check_result.select(&:success) }
            .inject(:&)
            .map { |check_result| check_result.labels[:shard] }
            .compact
            .uniq
        end
      end
    end
  end
end

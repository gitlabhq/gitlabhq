module Geo
  class RepositorySyncWorker
    include ApplicationWorker
    include CronjobQueue

    HEALTHY_SHARD_CHECKS = [
      Gitlab::HealthChecks::FsShardsCheck,
      Gitlab::HealthChecks::GitalyCheck
    ].freeze

    def perform
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?

      shards = healthy_shards

      Gitlab::Geo::ShardHealthCache.update(shards)

      shards.each do |shard_name|
        RepositoryShardSyncWorker.perform_async(shard_name)
      end
    end

    def healthy_shards
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

module Geo
  class RepositorySyncWorker
    include ApplicationWorker
    include CronjobQueue

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
      Gitlab::HealthChecks::FsShardsCheck
        .readiness
        .select(&:success)
        .map { |check| check.labels[:shard] }
        .compact
        .uniq
    end
  end
end

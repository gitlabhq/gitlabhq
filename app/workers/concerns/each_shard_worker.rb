module EachShardWorker
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize

  HEALTHY_SHARD_CHECKS = [
    Gitlab::HealthChecks::GitalyCheck
  ].freeze

  def each_eligible_shard
    Gitlab::ShardHealthCache.update(eligible_shard_names)

    eligible_shard_names.each do |shard_name|
      yield shard_name
    end
  end

  # override when you want to filter out some shards
  def eligible_shard_names
    healthy_shard_names
  end

  def healthy_shard_names
    strong_memoize(:healthy_shard_names) do
      # For now, we need to perform both Gitaly and direct filesystem checks to ensure
      # the shard is healthy. We take the intersection of the successful checks
      # as the healthy shards.
      healthy_ready_shards.map { |result| result.labels[:shard] }.compact.uniq
    end
  end

  def healthy_ready_shards
    ready_shards.map { |result| result.select(&:success) }.inject(:&)
  end

  def ready_shards
    HEALTHY_SHARD_CHECKS.map(&:readiness)
  end
end

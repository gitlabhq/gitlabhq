# frozen_string_literal: true

module EachShardWorker
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize

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
      healthy_ready_shards.map { |result| result.labels[:shard] }
    end
  end

  def healthy_ready_shards
    ready_shards.select(&:success)
  end

  def ready_shards
    Gitlab::HealthChecks::GitalyCheck.readiness
  end
end

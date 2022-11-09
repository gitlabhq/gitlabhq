# frozen_string_literal: true

class GitlabPerformanceBarStatsWorker
  include ApplicationWorker

  data_consistency :always
  worker_resource_boundary :cpu

  sidekiq_options retry: 3

  LEASE_KEY = 'gitlab:performance_bar_stats'
  LEASE_TIMEOUT = 600
  WORKER_DELAY = 120
  STATS_KEY = 'performance_bar_stats:pending_request_ids'
  STATS_KEY_EXPIRE = 30.minutes.to_i

  feature_category :metrics
  idempotent!

  def perform(lease_uuid)
    with_redis do |redis|
      request_ids = fetch_request_ids(redis, lease_uuid)
      stats = Gitlab::PerformanceBar::Stats.new(redis)

      request_ids.each do |id|
        stats.process(id)
      end
    end
  end

  private

  def with_redis(&block)
    Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
  end

  def fetch_request_ids(redis, lease_uuid)
    ids = redis.smembers(STATS_KEY)
    redis.del(STATS_KEY)
    Gitlab::ExclusiveLease.cancel(LEASE_KEY, lease_uuid)

    ids
  end
end

# frozen_string_literal: true

class GitlabPerformanceBarStatsWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  LEASE_KEY = 'gitlab:performance_bar_stats'
  LEASE_TIMEOUT = 600
  WORKER_DELAY = 120
  STATS_KEY = 'performance_bar_stats:pending_request_ids'
  STATS_KEY_EXPIRE = 30.minutes.to_i

  feature_category :metrics
  tags :exclude_from_kubernetes
  idempotent!

  def perform(lease_uuid)
    Gitlab::Redis::Cache.with do |redis|
      request_ids = fetch_request_ids(redis, lease_uuid)
      stats = Gitlab::PerformanceBar::Stats.new(redis)

      request_ids.each do |id|
        stats.process(id)
      end
    end
  end

  private

  def fetch_request_ids(redis, lease_uuid)
    ids = redis.smembers(STATS_KEY)
    redis.del(STATS_KEY)
    Gitlab::ExclusiveLease.cancel(LEASE_KEY, lease_uuid)

    ids
  end
end

# frozen_string_literal: true

class GitlabPerformanceBarStatsWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- context is not needed

  data_consistency :always
  worker_resource_boundary :cpu

  sidekiq_options retry: 3

  STATS_KEY = 'performance_bar_stats:pending_request_ids'
  STATS_KEY_EXPIRE = 30.minutes.to_i

  feature_category :observability
  idempotent!

  # _uuid is kept for backward compatibility, but it's not used anymore
  def perform(_uuid = nil)
    with_redis do |redis|
      request_ids = fetch_request_ids(redis)
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

  def fetch_request_ids(redis)
    ids = redis.smembers(STATS_KEY)
    redis.del(STATS_KEY)

    ids
  end
end

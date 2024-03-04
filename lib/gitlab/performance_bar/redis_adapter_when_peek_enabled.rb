# frozen_string_literal: true

# Adapted from https://github.com/peek/peek/blob/master/lib/peek/adapters/redis.rb
module Gitlab
  module PerformanceBar
    module RedisAdapterWhenPeekEnabled
      def save(request_id)
        return unless ::Gitlab::PerformanceBar.enabled_for_request?
        return if request_id.blank?

        super

        enqueue_stats_job(request_id)
      end

      # schedules a job which parses peek profile data and adds them
      # to a structured log
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      # rubocop:disable CodeReuse/ActiveRecord -- needed because of `.exists?` method
      # usage (which is actually not AR method)
      def enqueue_stats_job(request_id)
        return unless Feature.enabled?(:performance_bar_stats, type: :ops)

        cache_existed = @client.exists?(GitlabPerformanceBarStatsWorker::STATS_KEY)
        @client.sadd?(GitlabPerformanceBarStatsWorker::STATS_KEY, request_id)

        return if cache_existed

        # stats key should be periodically processed and deleted by
        # GitlabPerformanceBarStatsWorker but if it doesn't happen for
        # some reason, we set expiration for the stats key to avoid
        # keeping millions of request ids which would be already expired
        # anyway
        @client.expire(
          GitlabPerformanceBarStatsWorker::STATS_KEY,
          GitlabPerformanceBarStatsWorker::STATS_KEY_EXPIRE
        )
      end
      # rubocop:enable CodeReuse/ActiveRecord
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end

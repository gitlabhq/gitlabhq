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
      def enqueue_stats_job(request_id)
        return unless gather_stats?

        @client.sadd(GitlabPerformanceBarStatsWorker::STATS_KEY, request_id) # rubocop:disable Gitlab/ModuleWithInstanceVariables

        return unless uuid = Gitlab::ExclusiveLease.new(
          GitlabPerformanceBarStatsWorker::LEASE_KEY,
          timeout: GitlabPerformanceBarStatsWorker::LEASE_TIMEOUT
        ).try_obtain

        GitlabPerformanceBarStatsWorker.perform_in(GitlabPerformanceBarStatsWorker::WORKER_DELAY, uuid)
      end

      def gather_stats?
        return unless Feature.enabled?(:performance_bar_stats)

        Gitlab.com? || !Rails.env.production?
      end
    end
  end
end

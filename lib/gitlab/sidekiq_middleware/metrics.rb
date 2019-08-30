# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class Metrics
      # SIDEKIQ_LATENCY_BUCKETS are latency histogram buckets better suited to Sidekiq
      # timeframes than the DEFAULT_BUCKET definition. Defined in seconds.
      SIDEKIQ_LATENCY_BUCKETS = [0.1, 0.25, 0.5, 1, 2.5, 5, 10, 60, 300, 600].freeze

      def initialize
        @metrics = init_metrics
      end

      def call(_worker, job, queue)
        labels = create_labels(queue)
        @metrics[:sidekiq_running_jobs].increment(labels, 1)

        if job['retry_count'].present?
          @metrics[:sidekiq_jobs_retried_total].increment(labels, 1)
        end

        realtime = Benchmark.realtime do
          yield
        end

        @metrics[:sidekiq_jobs_completion_seconds].observe(labels, realtime)
      rescue Exception # rubocop: disable Lint/RescueException
        @metrics[:sidekiq_jobs_failed_total].increment(labels, 1)
        raise
      ensure
        @metrics[:sidekiq_running_jobs].increment(labels, -1)
      end

      private

      def init_metrics
        {
          sidekiq_jobs_completion_seconds: ::Gitlab::Metrics.histogram(:sidekiq_jobs_completion_seconds, 'Seconds to complete sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_failed_total:       ::Gitlab::Metrics.counter(:sidekiq_jobs_failed_total, 'Sidekiq jobs failed'),
          sidekiq_jobs_retried_total:      ::Gitlab::Metrics.counter(:sidekiq_jobs_retried_total, 'Sidekiq jobs retried'),
          sidekiq_running_jobs:            ::Gitlab::Metrics.gauge(:sidekiq_running_jobs, 'Number of Sidekiq jobs running', {}, :livesum)
        }
      end

      def create_labels(queue)
        {
          queue: queue
        }
      end
    end
  end
end

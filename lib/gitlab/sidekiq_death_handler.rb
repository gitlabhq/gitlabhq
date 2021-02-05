# frozen_string_literal: true

module Gitlab
  module SidekiqDeathHandler
    class << self
      include ::Gitlab::SidekiqMiddleware::MetricsHelper

      def handler(job, _exception)
        labels = create_labels(job['class'].constantize, job['queue'], job)

        counter.increment(labels)
      end

      def counter
        @counter ||= ::Gitlab::Metrics.counter(:sidekiq_jobs_dead_total, 'Sidekiq dead jobs')
      end
    end
  end
end

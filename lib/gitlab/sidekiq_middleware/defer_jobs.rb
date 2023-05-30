# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class DeferJobs
      include Sidekiq::ServerMiddleware

      DELAY = ENV.fetch("SIDEKIQ_DEFER_JOBS_DELAY", 5.minutes)
      FEATURE_FLAG_PREFIX = "defer_sidekiq_jobs"

      # This middleware will defer jobs indefinitely until the `defer_sidekiq_jobs_#{worker_name}` feature flag
      # is turned off (or when Feature.enabled? returns false by chance while using `percentage of time` value)
      def call(worker, job, _queue)
        if defer_job?(worker)
          job['deferred'] = true # for logging job_status
          worker.class.perform_in(DELAY, *job['args'])
          counter.increment({ worker: worker.class.name })
          return
        end

        yield
      end

      def defer_job?(worker)
        Feature.enabled?(:"#{FEATURE_FLAG_PREFIX}_#{worker.class.name}", type: :worker,
          default_enabled_if_undefined: false)
      end

      private

      def counter
        @counter ||= Gitlab::Metrics.counter(:sidekiq_jobs_deferred_total, 'The number of jobs deferred')
      end
    end
  end
end

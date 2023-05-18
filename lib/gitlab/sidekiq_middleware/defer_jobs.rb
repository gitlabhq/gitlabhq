# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class DeferJobs
      include Sidekiq::ServerMiddleware
      DELAY = ENV.fetch("SIDEKIQ_DEFER_JOBS_DELAY", 5.minutes)
      FEATURE_FLAG_PREFIX = "defer_sidekiq_jobs"

      # This middleware will defer jobs indefinitely until the `defer_sidekiq_jobs:#{worker_name}` feature flag
      # is turned off (or when Feature.enabled? returns false by chance while using `percentage of time` value)
      def call(worker, job, _queue)
        if defer_job?(worker)
          Sidekiq.logger.info(
            class: worker.class.name,
            job_id: job['jid'],
            message: "Deferring #{worker.class.name} for #{DELAY} s with arguments (#{job['args'].inspect})"
          )
          worker.class.perform_in(DELAY, *job['args'])
          return
        end

        yield
      end

      def defer_job?(worker)
        Feature.enabled?(:"#{FEATURE_FLAG_PREFIX}:#{worker.class.name}", type: :worker,
          default_enabled_if_undefined: false)
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class DeferJobs
      DELAY = ENV.fetch("SIDEKIQ_DEFER_JOBS_DELAY", 5.minutes)
      FEATURE_FLAG_PREFIX = "defer_sidekiq_jobs"

      DatabaseHealthStatusChecker = Struct.new(:id, :job_class_name)

      # There are 2 scenarios under which this middleware defers a job
      # 1. defer_sidekiq_jobs_#{worker_name} FF, jobs are deferred indefinitely until this feature flag
      #    is turned off or when Feature.enabled? returns false by chance while using `percentage of time` value.
      # 2. Gitlab::Database::HealthStatus, on evaluating the db health status if it returns any indicator
      #    with stop signal, the jobs will be delayed by 'x' seconds (set in worker).
      def call(worker, job, _queue)
        # ActiveJobs have wrapped class stored in 'wrapped' key
        resolved_class = job['wrapped']&.safe_constantize || worker.class
        defer_job, delay, deferred_by = defer_job_info(resolved_class, job)

        if !!defer_job
          # Referred in job_logger's 'log_job_done' method to compute proper 'job_status'
          job['deferred'] = true
          job['deferred_by'] = deferred_by

          worker.class.perform_in(delay, *job['args'])
          counter.increment({ worker: worker.class.name })

          # This breaks the middleware chain and return
          return
        end

        yield
      end

      private

      def defer_job_info(worker_class, job)
        if defer_job_by_ff?(worker_class)
          [true, DELAY, :feature_flag]
        elsif defer_job_by_database_health_signal?(job, worker_class)
          [true, worker_class.database_health_check_attrs[:delay_by], :database_health_check]
        end
      end

      def defer_job_by_ff?(worker_class)
        Feature.enabled?(
          :"#{FEATURE_FLAG_PREFIX}_#{worker_class.name}",
          type: :worker,
          default_enabled_if_undefined: false
        )
      end

      def defer_job_by_database_health_signal?(job, worker_class)
        unless worker_class.respond_to?(:defer_on_database_health_signal?) &&
            worker_class.defer_on_database_health_signal?
          return false
        end

        health_check_attrs = worker_class.database_health_check_attrs
        job_base_model = Gitlab::Database.schemas_to_base_models[health_check_attrs[:gitlab_schema]].first

        health_context = Gitlab::Database::HealthStatus::Context.new(
          DatabaseHealthStatusChecker.new(job['jid'], worker_class.name),
          job_base_model.connection,
          health_check_attrs[:gitlab_schema],
          health_check_attrs[:tables]
        )

        Gitlab::Database::HealthStatus.evaluate(health_context).any?(&:stop?)
      end

      def counter
        @counter ||= Gitlab::Metrics.counter(:sidekiq_jobs_deferred_total, 'The number of jobs deferred')
      end
    end
  end
end

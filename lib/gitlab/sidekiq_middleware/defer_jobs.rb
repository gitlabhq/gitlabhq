# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class DeferJobs
      DELAY = ENV.fetch("SIDEKIQ_DEFER_JOBS_DELAY", 5.minutes)
      RUN_FEATURE_FLAG_PREFIX = "run_sidekiq_jobs"

      DatabaseHealthStatusChecker = Struct.new(:id, :job_class_name)

      DEFERRED_COUNTER = :sidekiq_jobs_deferred_total

      def initialize
        @metrics = init_metrics
      end

      # There are 2 scenarios under which this middleware defers a job
      # 1. When run_sidekiq_jobs_#{worker_name} FF is disabled. This FF is enabled by default
      #    for all workers.
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
          job['deferred_count'] ||= 0
          job['deferred_count'] += 1

          worker.class.perform_in(delay, *job['args'])
          @metrics.fetch(DEFERRED_COUNTER).increment({ worker: worker.class.name })

          # This breaks the middleware chain and return
          return
        end

        yield
      end

      private

      def defer_job_info(worker_class, job)
        if !run_job_by_ff?(worker_class)
          [true, DELAY, :feature_flag]
        elsif defer_job_by_database_health_signal?(job, worker_class)
          [true, worker_class.database_health_check_attrs[:delay_by], :database_health_check]
        end
      end

      def run_job_by_ff?(worker_class)
        # always returns true by default for all workers unless the FF is specifically disabled, e.g. during an incident
        Feature.enabled?(
          :"#{RUN_FEATURE_FLAG_PREFIX}_#{worker_class.name}",
          type: :worker,
          default_enabled_if_undefined: true
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

      def init_metrics
        {
          DEFERRED_COUNTER => Gitlab::Metrics.counter(DEFERRED_COUNTER, 'The number of jobs deferred')
        }
      end
    end
  end
end

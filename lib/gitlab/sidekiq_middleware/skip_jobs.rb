# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class SkipJobs
      DELAY = ENV.fetch("SIDEKIQ_DEFER_JOBS_DELAY", 5.minutes)
      RUN_FEATURE_FLAG_PREFIX = "run_sidekiq_jobs"
      DROP_FEATURE_FLAG_PREFIX = "drop_sidekiq_jobs"

      DatabaseHealthStatusChecker = Struct.new(:id, :job_class_name)

      COUNTER = :sidekiq_jobs_skipped_total

      def initialize
        @metrics = init_metrics
      end

      # This middleware decides whether a job is dropped, deferred or runs normally.
      # In short:
      #   - `drop_sidekiq_jobs_#{worker_name}` FF enabled (disabled by default) --> drops the job
      #   - `run_sidekiq_jobs_#{worker_name}` FF disabled (enabled by default) --> defers the job
      #
      # DROPPING JOBS
      # A job is dropped when `drop_sidekiq_jobs_#{worker_name}` FF is enabled. This FF is disabled by default for
      # all workers. Dropped jobs are completely ignored and not requeued for future processing.
      #
      # DEFERRING JOBS
      # Deferred jobs are rescheduled to perform in the future.
      # There are 2 scenarios under which this middleware defers a job:
      # 1. When run_sidekiq_jobs_#{worker_name} FF is disabled. This FF is enabled by default
      #    for all workers.
      # 2. Gitlab::Database::HealthStatus, on evaluating the db health status if it returns any indicator
      #    with stop signal, the jobs will be delayed by 'x' seconds (set in worker).
      #
      # Dropping jobs takes higher priority over deferring jobs. For example, when `drop_sidekiq_jobs` is enabled and
      # `run_sidekiq_jobs` is disabled, it results to jobs being dropped.
      def call(worker, job, _queue)
        # ActiveJobs have wrapped class stored in 'wrapped' key
        resolved_class = job['wrapped']&.safe_constantize || worker.class
        if drop_job?(resolved_class)
          # no-op, drop the job entirely
          drop_job!(job, worker)
          return
        elsif !!defer_job?(resolved_class, job)
          defer_job!(job, worker)
          return
        end

        job.delete('deferred') if job['deferred']

        yield
      end

      private

      def defer_job?(worker_class, job)
        if !run_job_by_ff?(worker_class)
          @delay = DELAY
          @deferred_by = :feature_flag
          true
        elsif defer_job_by_database_health_signal?(job, worker_class)
          @delay = worker_class.database_health_check_attrs[:delay_by]
          @deferred_by = :database_health_check
          true
        end
      end

      def run_job_by_ff?(worker_class)
        # always returns true by default for all workers unless the FF is specifically disabled, e.g. during an incident
        Feature.enabled?(
          :"#{RUN_FEATURE_FLAG_PREFIX}_#{worker_class.name}",
          Feature.current_request,
          type: :worker,
          default_enabled_if_undefined: true
        )
      end

      def defer_job_by_database_health_signal?(job, worker_class)
        # ActionMailer's ActiveJob pushes a job hash with class: ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper
        # which won't be having :defer_on_database_health_signal? defined
        unless worker_class.respond_to?(:defer_on_database_health_signal?) &&
            worker_class.defer_on_database_health_signal?
          return false
        end

        health_check_attrs = worker_class.database_health_check_attrs

        tables, schema = health_check_attrs.values_at(:tables, :gitlab_schema)

        if health_check_attrs[:block].respond_to?(:call)
          schema, tables = health_check_attrs[:block].call(job['args'], schema, tables)
        end

        job_base_model = Gitlab::Database.schemas_to_base_models[schema].first

        health_context = Gitlab::Database::HealthStatus::Context.new(
          DatabaseHealthStatusChecker.new(job['jid'], worker_class.name),
          job_base_model.connection,
          tables
        )

        Gitlab::Database::HealthStatus.evaluate(health_context).any?(&:stop?)
      end

      def drop_job?(worker_class)
        Feature.enabled?(
          :"#{DROP_FEATURE_FLAG_PREFIX}_#{worker_class.name}",
          Feature.current_request,
          type: :worker,
          default_enabled_if_undefined: false
        )
      end

      def drop_job!(job, worker)
        job['dropped'] = true
        @metrics.fetch(COUNTER).increment({
          worker: worker.class.name,
          action: "dropped",
          reason: "feature_flag",
          feature_category: worker.class.get_feature_category.to_s
        })
      end

      def defer_job!(job, worker)
        # Referred in job_logger's 'log_job_done' method to compute proper 'job_status'
        job['deferred'] = true
        job['deferred_by'] = @deferred_by
        job['deferred_count'] ||= 0
        job['deferred_count'] += 1

        worker.class.deferred(job['deferred_count'], @deferred_by).perform_in(@delay, *job['args'])
        @metrics.fetch(COUNTER).increment({
          worker: worker.class.name,
          action: "deferred",
          reason: @deferred_by.to_s,
          feature_category: worker.class.get_feature_category.to_s
        })
      end

      def init_metrics
        {
          COUNTER => Gitlab::Metrics.counter(COUNTER, 'The number of skipped jobs')
        }
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class Middleware
        def initialize(worker, job)
          @worker = worker
          @job = job

          worker_class = worker.is_a?(Class) ? worker : worker.class
          @worker_class = worker_class.name
        end

        # This will continue the middleware chain if the job should be scheduled
        # It will return false if the job needs to be cancelled
        def schedule
          if should_defer_schedule?
            defer_job!
            return
          end

          yield
        end

        # This will continue the server middleware chain if the job should be
        # executed.
        # It will return false if the job should not be executed.
        def perform
          if should_defer_perform?
            defer_job!
            return
          end

          track_execution_start

          yield
        ensure
          track_execution_end
        end

        private

        attr_reader :job, :worker, :worker_class

        def should_defer_schedule?
          return false if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)
          return false if job['at'] # scheduled jobs can be later assessed on enqueue
          return false if resumed?
          return false if worker_limit == 0

          has_jobs_in_queue?
        end

        def should_defer_perform?
          return false if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)

          return false if resumed?
          return true if has_jobs_in_queue?

          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.over_the_limit?(worker: worker)
        end

        def concurrency_service
          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService
        end

        def track_execution_start
          return if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)
          return unless worker_limit > 0

          concurrency_service.track_execution_start(worker_class)
        end

        def track_execution_end
          return if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)
          return unless worker_limit > 0

          concurrency_service.track_execution_end(worker_class)
        end

        def worker_limit
          @worker_limit ||= ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: worker)
        end

        def resumed?
          job['concurrency_limit_resume'] == true
        end

        def has_jobs_in_queue?
          concurrency_service.has_jobs_in_queue?(worker_class)
        end

        def defer_job!
          ::Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.deferred_log(job)

          concurrency_service.add_to_queue!(
            job,
            current_context
          )
        end

        def current_context
          ::Gitlab::ApplicationContext.current
        end
      end
    end
  end
end

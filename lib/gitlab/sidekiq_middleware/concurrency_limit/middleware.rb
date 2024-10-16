# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class Middleware
        def initialize(worker, job)
          @worker = worker
          @job = job
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

          yield
        end

        private

        attr_reader :job, :worker

        def should_defer_schedule?
          return false if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)
          return false if resumed?
          return false unless ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: worker)

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

        def resumed?
          job['concurrency_limit_resume'] == true
        end

        def has_jobs_in_queue?
          worker_class = worker.is_a?(Class) ? worker : worker.class
          concurrency_service.has_jobs_in_queue?(worker_class.name)
        end

        def defer_job!
          ::Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.deferred_log(job)

          concurrency_service.add_to_queue!(
            job['class'],
            job['args'],
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

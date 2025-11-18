# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class Middleware
        def initialize(worker, job)
          @worker = worker
          @job = job

          @worker_class = if worker.is_a?(Class)
                            worker
                          elsif worker.is_a?(String)
                            worker.safe_constantize
                          else
                            worker.class
                          end

          @worker_name = worker_class ? worker_class.name : nil
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
          cleanup_stale_trackers
        end

        private

        attr_reader :job, :worker, :worker_name, :worker_class

        def should_defer_schedule?
          return false if disabled_for_worker?
          return false if job['at'] # scheduled jobs can be later assessed on enqueue
          return false if resumed?
          return false if worker_limit == 0

          has_jobs_in_queue?
        end

        def should_defer_perform?
          return false if disabled_for_worker?
          return false if resumed?
          return true if has_jobs_in_queue?

          concurrency_service.over_the_limit?(worker_name)
        end

        def concurrency_service
          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService
        end

        def track_execution_start
          return if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)

          concurrency_service.track_execution_start(worker_name)
        end

        def track_execution_end
          return if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)

          concurrency_service.track_execution_end(worker_name)
        end

        def cleanup_stale_trackers
          return if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)

          concurrency_service.cleanup_stale_trackers(worker_name)
        end

        def worker_limit
          worker_class.respond_to?(:get_concurrency_limit) ? worker_class.get_concurrency_limit : 0
        end

        def resumed?
          job['concurrency_limit_resume'] == true
        end

        def has_jobs_in_queue?
          concurrency_service.has_jobs_in_queue?(worker_name)
        end

        def current_count
          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.concurrent_worker_count(worker_name)
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

        def disabled_for_worker?
          Feature.enabled?(
            :"disable_sidekiq_concurrency_limit_middleware_#{worker_name}", # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- need to check against worker name dynamically
            Feature.current_request,
            type: :worker,
            default_enabled_if_undefined: false
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Throttling
      class RecoveryService
        def initialize(worker_name)
          @worker_name = worker_name
          @worker_klass = worker_name.safe_constantize
        end

        def execute
          # SidekiqMiddleware::Throttling::Middleware would have / will throttle this, no need to recover this worker
          # in the meantime
          return if needs_throttle?

          recover!
        end

        private

        attr_reader :worker_name, :worker_klass

        def recover!
          current = current_limit
          max = max_limit

          # Don't exceed the max limit
          new_limit = [recovery_strategy.concurrency_operator.call(current), max].min
          set_current_limit!(limit: new_limit)

          Sidekiq.logger.info(
            message: "Recovering concurrency limit for #{worker_name}",
            recovery_strategy: recovery_strategy.name,
            class: worker_name,
            previous_concurrency_limit: current,
            new_concurrency_limit: new_limit,
            max_concurrency_limit: max
          )

          return unless new_limit == max

          # won't be considered for recovery after this
          Gitlab::SidekiqMiddleware::Throttling::Tracker.new(worker_name).remove_from_throttled_list!
        end

        def needs_throttle?
          Gitlab::SidekiqMiddleware::Throttling::Decider.new(worker_name).execute.needs_throttle
        end

        def max_limit
          worker_klass.get_concurrency_limit
        end

        def recovery_strategy
          Gitlab::SidekiqMiddleware::Throttling::Strategy::GradualRecovery
        end

        def current_limit
          concurrency_limit_service.current_limit(worker_name)
        end

        def set_current_limit!(limit:)
          concurrency_limit_service.set_current_limit!(worker_name, limit: limit)
        end

        def concurrency_limit_service
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService
        end
      end
    end
  end
end

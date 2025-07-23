# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Throttling
      class Middleware
        include ExclusiveLeaseGuard

        LEASE_TIMEOUT = 5

        def initialize(worker)
          @worker_class = worker.is_a?(Class) ? worker : worker.class
          @worker_name = worker_class.name
          @tracker = Gitlab::SidekiqMiddleware::Throttling::Tracker.new(worker_name)
        end

        def perform
          return yield if Feature.disabled?(:sidekiq_throttling_middleware, Feature.current_request, type: :worker)

          # TODO: Will be moved out to read from Redis. See https://gitlab.com/gitlab-com/gl-infra/data-access/durability/team/-/issues/221
          if Feature.enabled?(
            :"disable_sidekiq_throttling_middleware_#{worker_class.name}", # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- need to check against worker name
            Feature.current_request,
            type: :worker,
            default_enabled_if_undefined: false
          )
            return yield
          end

          try_obtain_lease do
            next if already_throttled?

            decision = throttling_decision
            next unless decision.needs_throttle

            throttle!(decision.strategy)
          end

          yield
        end

        private

        attr_reader :worker_class, :worker_name, :decisions, :tracker

        def lease_key
          "#{self.class.name.underscore}:#{worker_name.underscore}"
        end

        def lease_timeout
          LEASE_TIMEOUT
        end

        def lease_release?
          false
        end

        def throttling_decision
          Gitlab::SidekiqMiddleware::Throttling::Decider.new(worker_name).execute
        end

        def throttle!(strategy)
          current = current_limit

          # limit 0 means no throttling in place, throttling will set the new limit to 1,
          # causing the floodgate to close immediately.
          return if current == 0

          new_limit = strategy.concurrency_operator.call(current)
          set_current_limit!(limit: new_limit)

          Sidekiq.logger.info(
            class: worker_name,
            throttling_decision: strategy.name,
            previous_concurrency_limit: current,
            new_concurrency_limit: new_limit,
            message: "#{worker_name} is throttled with strategy #{strategy.name}." \
          )

          tracker.record
          throttling_counter.increment({
            worker: worker_name,
            strategy: strategy.name,
            feature_category: worker_class.get_feature_category
          })
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

        def already_throttled?
          tracker.currently_throttled?
        end

        def throttling_counter
          @throttling_counter ||= ::Gitlab::Metrics.counter(:sidekiq_throttling_events_total,
            'Total number of sidekiq throttling events')
        end
      end
    end
  end
end

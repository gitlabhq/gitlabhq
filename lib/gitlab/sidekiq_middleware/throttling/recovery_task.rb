# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Throttling
      class RecoveryTask
        include ExclusiveLeaseGuard

        LEASE_TTL = 1.minute
        MIN_SLEEP_INTERVAL = 20.seconds
        MAX_SLEEP_INTERVAL = 40.seconds

        def initialize
          @alive = true
        end

        def call
          while @alive
            sleep(sleep_interval)

            next if ::Feature.disabled?(:sidekiq_throttling_middleware, :instance, type: :worker)

            try_obtain_lease { recover_workers }
          end
        end

        def stop
          @alive = false
        end

        private

        def lease_timeout
          LEASE_TTL
        end

        def lease_release?
          false
        end

        def sleep_interval
          rand(MIN_SLEEP_INTERVAL.to_f..MAX_SLEEP_INTERVAL.to_f)
        end

        def recover_workers
          throttled_workers.shuffle.each do |worker_name|
            Gitlab::SidekiqMiddleware::Throttling::RecoveryService.new(worker_name).execute
          end
        end

        def throttled_workers
          Gitlab::SidekiqMiddleware::Throttling::Tracker.throttled_workers
        end
      end
    end
  end
end

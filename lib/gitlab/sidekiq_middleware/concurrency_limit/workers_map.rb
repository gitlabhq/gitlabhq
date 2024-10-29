# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class WorkersMap
        class << self
          def set_limit_for(worker:, max_jobs:)
            raise ArgumentError, 'max_jobs must be a Proc instance' if max_jobs && !max_jobs.is_a?(Proc)

            @data ||= {}
            @data[worker] = max_jobs
          end

          # Returns an integer value where:
          # - positive value is returned to enforce a valid concurrency limit
          # - 0 value is returned for workers without concurrency limits
          # - negative value is returned for paused workers
          def limit_for(worker:)
            return 0 unless data
            return 0 if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)

            worker_class = worker.is_a?(Class) ? worker : worker.class
            data[worker_class]&.call.to_i
          end

          def over_the_limit?(worker:)
            limit = limit_for(worker: worker)
            return false if limit == 0
            return true if limit < 0

            current = current_count(worker)

            current >= limit
          end

          def workers
            return [] unless data

            data.keys
          end

          private

          def current_count(worker)
            worker_class = worker.is_a?(Class) ? worker : worker.class
            worker_name = worker_class.name
            ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.concurrent_worker_count(worker_name)
          end

          attr_reader :data
        end
      end
    end
  end
end

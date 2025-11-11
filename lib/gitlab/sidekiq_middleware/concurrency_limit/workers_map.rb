# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class WorkersMap
        @data = {}
        class << self
          def set_limit_for(worker:, max_jobs:)
            raise ArgumentError, 'max_jobs must be a Proc instance' if max_jobs && !max_jobs.is_a?(Proc)

            @data[worker] = max_jobs
          end

          # Returns an integer value where:
          # - positive value is returned to enforce a valid concurrency limit
          # - 0 value is returned for workers without concurrency limits
          # - negative value is returned for paused workers
          def limit_for(worker:)
            return 0 if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)

            worker_class = worker.is_a?(Class) ? worker : worker.class
            limit = data[worker_class]&.call
            return limit.to_i unless limit.nil?

            default_limit_from_max_percentage(worker_class)
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

          # Default limit based on urgency and number of total Sidekiq threads in the fleet.
          # e.g. for low urgency worker class, maximum 20% of all Sidekiq workers can run concurrently.
          def default_limit_from_max_percentage(worker)
            return 0 unless worker.ancestors.include?(WorkerAttributes)

            max_replicas = ENV.fetch('GITLAB_SIDEKIQ_MAX_REPLICAS', '0').to_i
            concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', '0').to_i
            max_total_threads = max_replicas * concurrency
            percentage = worker.get_max_concurrency_limit_percentage

            (percentage * max_total_threads).ceil
          end

          attr_reader :data
        end
      end
    end
  end
end

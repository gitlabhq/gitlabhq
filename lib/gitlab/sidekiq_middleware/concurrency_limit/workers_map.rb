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

          def limit_for(worker:)
            return unless data
            return if Feature.disabled?(:sidekiq_concurrency_limit_middleware, Feature.current_request, type: :ops)

            worker_class = worker.is_a?(Class) ? worker : worker.class
            data[worker_class]
          end

          def over_the_limit?(worker:)
            limit_proc = limit_for(worker: worker)

            limit = limit_proc&.call.to_i
            return false if limit == 0
            return true if limit < 0

            current = ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersConcurrency.current_for(worker: worker)

            current >= limit
          end

          def workers
            return [] unless data

            data.keys
          end

          private

          attr_reader :data
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ResourceUsageLimit
      class Middleware
        include ::Gitlab::SidekiqMiddleware::WorkerContext

        def initialize(worker, job)
          @worker = worker
          @job = job
          @worker_name = name_from_class(worker, job)
        end

        def perform
          yield

          track_resource_usage
        end

        attr_reader :worker_name

        private

        def track_resource_usage
          return unless Feature.enabled?(:enable_sidekiq_resource_usage_tracking, :current_request, type: :ops)

          limiter = Gitlab::ResourceUsageLimiter.new(worker_name: worker_name)
          limiter.exceeded_limits
        end

        def name_from_class(worker_class, job)
          worker = find_worker(worker_class, job)
          worker.try(:name) || worker.class.name
        end
      end
    end
  end
end

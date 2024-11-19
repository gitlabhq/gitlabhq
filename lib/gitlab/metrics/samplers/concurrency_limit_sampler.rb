# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class ConcurrencyLimitSampler < BaseSampler
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 60

        def sample
          worker_maps.workers.each do |w|
            queue_size = concurrent_limit_service.queue_size(w.name)
            report_queue_size(w.name, queue_size) if queue_size > 0

            concurrent_worker_count = concurrent_limit_service.concurrent_worker_count(w.name)
            report_concurrent_workers(w.name, concurrent_worker_count) if concurrent_worker_count > 0
          end
        end

        private

        def worker_maps
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap
        end

        def concurrent_limit_service
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService
        end

        def report_queue_size(worker_name, queue_size)
          @queue_size_metric ||= Gitlab::Metrics.counter(:sidekiq_concurrency_limit_queue_jobs_total,
            'Number of jobs queued by the concurrency limit middleware.')
          @queue_size_metric.increment({ worker: worker_name }, queue_size)
        end

        def report_concurrent_workers(worker_name, concurrent_worker_count)
          @concurrency_metric ||= Gitlab::Metrics.counter(:sidekiq_concurrency_limit_current_concurrent_jobs_total,
            'Current number of concurrent running jobs.')
          @concurrency_metric.increment({ worker: worker_name }, concurrent_worker_count)
        end
      end
    end
  end
end

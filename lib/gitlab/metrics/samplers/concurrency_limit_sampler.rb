# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class ConcurrencyLimitSampler < BaseSampler
        include ExclusiveLeaseGuard

        DEFAULT_SAMPLING_INTERVAL_SECONDS = 30

        def sample
          try_obtain_lease do
            worker_maps.workers.each do |w|
              queue_size = concurrent_limit_service.queue_size(w.name)
              report_queue_size(w, queue_size) if queue_size > 0

              concurrent_worker_count = concurrent_limit_service.concurrent_worker_count(w.name)
              report_concurrent_workers(w, concurrent_worker_count) if concurrent_worker_count > 0
            end
          end
        end

        private

        # Used by ExclusiveLeaseGuard
        def lease_timeout
          # Lease timeout and sampling interval should be the same
          # so that only 1 process runs the sampler on every sampling interval
          DEFAULT_SAMPLING_INTERVAL_SECONDS
        end

        # Overrides ExclusiveLeaseGuard to not release lease after the sample to ensure we do not oversample
        def lease_release?
          false
        end

        def worker_maps
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap
        end

        def concurrent_limit_service
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService
        end

        def report_queue_size(worker, queue_size)
          @queue_size_metric ||= Gitlab::Metrics.counter(:sidekiq_concurrency_limit_queue_jobs_total,
            'Number of jobs queued by the concurrency limit middleware.')
          @queue_size_metric.increment({ worker: worker.name, feature_category: worker.get_feature_category },
            queue_size)
        end

        def report_concurrent_workers(worker, concurrent_worker_count)
          @concurrency_metric ||= Gitlab::Metrics.counter(:sidekiq_concurrency_limit_current_concurrent_jobs_total,
            'Current number of concurrent running jobs.')
          @concurrency_metric.increment({ worker: worker.name, feature_category: worker.get_feature_category },
            concurrent_worker_count)
        end
      end
    end
  end
end

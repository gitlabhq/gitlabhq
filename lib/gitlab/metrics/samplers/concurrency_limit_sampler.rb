# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class ConcurrencyLimitSampler < BaseSampler
        include ExclusiveLeaseGuard

        # Scrape timing explanation:
        # - Prometheus scrapes occur every 1 minute
        # - Our sampler lease lasts for 5 minutes
        # - After writing metrics, we sleep for 30s until lease expires before resetting the metrics to 0.
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 30
        LEASE_TIMEOUT = 300

        # The sleep ensures that:
        # 1. Process A runs sampler and takes the lease
        # 2. Other processes running sampler will not be able to take the lease, so they will be no-ops
        # 3. While the lease still exists (for 5 minutes):
        #   a. The sampler writes the metrics
        #   b. The sampler sleeps for 30s
        #   c. We hope scrapes happen here (occur every minute), so we expect 4 or 5 scrapes for 1 sampler
        # 4. Reset metrics to 0
        # 5. The first other process picks up the lease, goto 1
        #
        # Therefore we ensure that on every scrape, 1 process would report the correct data
        # while the process that previously held lease report 0.
        def sample
          try_obtain_lease do
            # Keep reporting the metrics while the lease is valid
            # to ensure we have continuous data. Also check if the
            # sampler is still running because a SIGTERM will cause
            # the sleep to be interrupted and the loop to run again
            # until the condition is false.
            while running && exclusive_lease.same_uuid?
              report_metrics

              # Ensure that we don't sleep if the state changed
              # after reporting metrics.
              break unless running

              Kernel.sleep(DEFAULT_SAMPLING_INTERVAL_SECONDS)
            end

            # Reset metrics to ensure only the next sample reports fresh data.
            reset_metrics
          end
        end

        private

        # Used by ExclusiveLeaseGuard
        def lease_timeout
          LEASE_TIMEOUT
        end

        def lease_key
          "#{self.class.name.underscore}:queues:#{current_queues.join(',')}"
        end

        def lease_taken_log_level
          :info
        end

        def report_metrics
          workers.each do |w|
            queue_size = concurrent_limit_service.queue_size(w.name)
            report_queue_size(w, queue_size)

            concurrent_worker_count = concurrent_limit_service.concurrent_worker_count(w.name)
            report_concurrent_workers(w, concurrent_worker_count)

            max_limit = w.get_concurrency_limit
            report_max_limit(w, max_limit)

            current_limit = concurrent_limit_service.current_limit(w.name)
            report_current_limit(w, current_limit)
          end
        end

        def reset_metrics
          workers.each do |w|
            report_queue_size(w, 0)
            report_concurrent_workers(w, 0)
            report_max_limit(w, 0)
            report_current_limit(w, 0)
          end
        end

        def workers
          @workers ||= Gitlab::SidekiqConfig
                         .workers_without_default
                         .select do |worker|
                           queue = ::Gitlab::SidekiqConfig::WorkerRouter.global.route(worker.klass)
                           current_queues.include?(queue)
                         end
                         .map(&:klass)
        end

        def current_queues
          Sidekiq.default_configuration.queues
        end

        def concurrent_limit_service
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService
        end

        def report_queue_size(worker, queue_size)
          @queue_size_metric ||= Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_queue_jobs,
            'Number of jobs queued by the concurrency limit middleware.')
          @queue_size_metric.set({ worker: worker.name, feature_category: worker.get_feature_category }, queue_size)
        end

        def report_concurrent_workers(worker, concurrent_worker_count)
          @concurrency_metric ||= Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_current_concurrent_jobs,
            'Current number of concurrent running jobs.')
          @concurrency_metric.set({ worker: worker.name, feature_category: worker.get_feature_category },
            concurrent_worker_count)
        end

        def report_max_limit(worker, limit)
          @limit_metric ||= Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_max_concurrent_jobs,
            'Max number of concurrent running jobs.')
          @limit_metric.set({ worker: worker.name, feature_category: worker.get_feature_category }, limit)
        end

        def report_current_limit(worker, limit)
          @current_limit_metric ||= Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_current_limit,
            'Number of concurrent jobs currently allowed to run subject to throttling.')
          @current_limit_metric.set({ worker: worker.name, feature_category: worker.get_feature_category }, limit)
        end
      end
    end
  end
end

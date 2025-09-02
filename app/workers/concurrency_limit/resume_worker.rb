# frozen_string_literal: true

module ConcurrencyLimit
  class ResumeWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- There is no onward scheduling and this cron handles work from across the
    # application, so there's no useful context to add.

    BATCH_SIZE = 5_000
    RESCHEDULE_DELAY = 1.second

    feature_category :scalability
    data_consistency :sticky
    idempotent!
    urgency :low

    def perform(worker_name = nil)
      if worker_name
        process_worker(worker_name)
      else
        schedule_workers
      end
    end

    private

    def schedule_workers
      workers.each do |worker|
        limit = worker.get_concurrency_limit
        queue_size = queue_size(worker)

        next unless queue_size > 0
        next if limit < 0 # do not re-queue jobs if circuit-broken

        self.class.perform_async(worker.name)
      end
    end

    def process_worker(worker_name)
      worker = worker_name.safe_constantize
      return unless worker

      limit = worker_limit(worker)
      queue_size = queue_size(worker)
      current = concurrent_worker_count(worker)

      return unless queue_size > 0
      return if limit < 0 # do not re-queue jobs if circuit-broken

      Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.worker_stats_log(
        worker.name, limit, queue_size, current
      )

      processing_limit = if limit > 0
                           limit - current
                         else
                           BATCH_SIZE
                         end

      return unless processing_limit > 0

      resume_processing!(worker, limit: processing_limit)
      cleanup_stale_trackers(worker)

      queue_remaining_count = queue_size - processing_limit
      self.class.perform_in(RESCHEDULE_DELAY, worker_name) if queue_remaining_count > 0
    end

    def concurrent_worker_count(worker)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.concurrent_worker_count(worker.name)
    end

    def queue_size(worker)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.queue_size(worker.name)
    end

    def cleanup_stale_trackers(worker)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.cleanup_stale_trackers(worker.name)
    end

    def resume_processing!(worker, limit:)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.resume_processing!(worker.name, limit: limit)
    end

    def worker_limit(worker)
      if Feature.disabled?(:concurrency_limit_current_limit_from_redis, Feature.current_request)
        return worker.get_concurrency_limit
      end

      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.current_limit(worker.name)
    end

    def workers
      Gitlab::SidekiqConfig.workers_without_default.map(&:klass)
    end
  end
end

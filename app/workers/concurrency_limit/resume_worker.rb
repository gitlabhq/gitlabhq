# frozen_string_literal: true

module ConcurrencyLimit
  class ResumeWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- There is no onward scheduling and this cron handles work from across the
    # application, so there's no useful context to add.

    BATCH_SIZE = 1_000
    RESCHEDULE_DELAY = 1.second

    feature_category :global_search
    data_consistency :sticky
    idempotent!
    urgency :low

    def perform
      reschedule_job = false

      workers.each do |worker|
        limit = ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: worker)
        queue_size = queue_size(worker)
        current = current_concurrency(worker: worker)
        report_prometheus_metrics(worker, queue_size, limit, current)

        next unless queue_size > 0
        next if limit < 0 # do not re-queue jobs if circuit-broken

        reschedule_job = true

        processing_limit = if limit > 0
                             limit - current
                           else
                             BATCH_SIZE
                           end

        next unless processing_limit > 0

        resume_processing!(worker, limit: processing_limit)
        cleanup_stale_trackers(worker)
      end

      self.class.perform_in(RESCHEDULE_DELAY) if reschedule_job
    end

    private

    def current_concurrency(worker:)
      if ::Feature.enabled?(:sidekiq_concurrency_limit_optimized_count, Feature.current_request)
        return concurrent_worker_count(worker)
      end

      @current_concurrency ||= ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersConcurrency.workers(
        skip_cache: true
      )

      @current_concurrency[worker.name].to_i
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

    def workers
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.workers
    end

    def report_prometheus_metrics(worker, queue_size, limit, currently_executing)
      queue_size_metric = Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_queue_jobs,
        'Number of jobs queued by the concurrency limit middleware.',
        {},
        :max)
      queue_size_metric.set({ worker: worker.name }, queue_size)

      limit_metric = Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_max_concurrent_jobs,
        'Max number of concurrent running jobs.',
        {})
      limit_metric.set({ worker: worker.name }, limit || BATCH_SIZE)

      concurrency_metric = Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_current_concurrent_jobs,
        'Current number of concurrent running jobs.',
        {})
      concurrency_metric.set({ worker: worker.name }, currently_executing)
    end
  end
end

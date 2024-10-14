# frozen_string_literal: true

module ConcurrencyLimit
  class ResumeWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- There is no onward scheduling and this cron handles work from across the
    # application, so there's no useful context to add.

    DEFAULT_LIMIT = 1_000
    RESCHEDULE_DELAY = 1.second

    feature_category :global_search
    data_consistency :sticky
    idempotent!
    urgency :low

    def perform
      reschedule_job = false

      workers.each do |worker|
        limit = ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: worker)&.call
        queue_size = queue_size(worker)
        report_prometheus_metrics(worker, queue_size, limit)

        next unless queue_size > 0

        reschedule_job = true

        processing_limit = if limit
                             current = current_concurrency(worker: worker)
                             limit - current
                           else
                             DEFAULT_LIMIT
                           end

        next unless processing_limit > 0

        resume_processing!(worker, limit: processing_limit)
      end

      self.class.perform_in(RESCHEDULE_DELAY) if reschedule_job
    end

    private

    def current_concurrency(worker:)
      @current_concurrency ||= ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersConcurrency.workers(
        skip_cache: true
      )

      @current_concurrency[worker.name].to_i
    end

    def queue_size(worker)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.queue_size(worker.name)
    end

    def resume_processing!(worker, limit:)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.resume_processing!(worker.name, limit: limit)
    end

    def workers
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.workers
    end

    def report_prometheus_metrics(worker, queue_size, limit)
      queue_size_metric = Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_queue_jobs,
        'Number of jobs queued by the concurrency limit middleware.',
        {},
        :max)
      queue_size_metric.set({ worker: worker.name }, queue_size)

      limit_metric = Gitlab::Metrics.gauge(:sidekiq_concurrency_limit_max_concurrent_jobs,
        'Max number of concurrent running jobs.',
        {})
      limit_metric.set({ worker: worker.name }, limit || DEFAULT_LIMIT)
    end
  end
end

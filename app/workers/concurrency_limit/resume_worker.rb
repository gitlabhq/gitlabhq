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
        next unless jobs_in_the_queue?(worker)

        reschedule_job = true

        limit = ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: worker)&.call

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

    def jobs_in_the_queue?(worker)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.has_jobs_in_queue?(worker.name)
    end

    def resume_processing!(worker, limit:)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.resume_processing!(worker.name, limit: limit)
    end

    def workers
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.workers
    end
  end
end

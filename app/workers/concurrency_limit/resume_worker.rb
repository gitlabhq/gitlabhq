# frozen_string_literal: true

module ConcurrencyLimit
  class ResumeWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- There is no onward scheduling and this cron handles work from across the
    # application, so there's no useful context to add.

    RESCHEDULE_DELAY = 1.second

    feature_category :scalability
    data_consistency :sticky
    idempotent!
    urgency :low
    loggable_arguments 0

    # Do not defer jobs from ResumeWorker itself
    concurrency_limit -> { 0 }

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

        schedule_worker(worker)
      end
    end

    def schedule_worker(worker)
      Gitlab::SidekiqSharding::Router.route(worker) do
        # Schedules ResumeWorker job to the respective queue of the `worker` we're resuming.
        # This is because `worker_limit` requires reading environment variables unique each sidekiq shard,
        # whereas ResumeWorker (cronjob) always runs in the default queue.
        Sidekiq::Client.push('class' => self.class, 'args' => [worker.name], 'queue' => queue_for_worker(worker))
      end
    end

    def process_worker(worker_name)
      worker = worker_name.safe_constantize
      return unless worker

      limit = worker_limit(worker)
      queue_size = queue_size(worker)
      current = concurrent_worker_count(worker)
      to_resume = limit - current

      return unless queue_size > 0
      return if limit < 0 # do not re-queue jobs if circuit-broken
      return if limit != 0 && to_resume <= 0

      Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.worker_stats_log(
        worker.name, limit, queue_size, current
      )

      resumed_jobs_num = resume_processing!(worker)
      cleanup_stale_trackers(worker)

      if queue_size(worker) > 0
        Gitlab::SidekiqSharding::Router.route(worker) do
          Sidekiq::Client.enqueue_to_in(queue_for_worker(worker), RESCHEDULE_DELAY, self.class, worker.name)
        end
      end

      log_extra_metadata_on_done(:resumed_jobs, resumed_jobs_num)
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

    def resume_processing!(worker)
      Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.resume_processing!(worker.name)
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

    def queue_for_worker(worker)
      ::Gitlab::SidekiqConfig::WorkerRouter.global.route(worker)
    end
  end
end

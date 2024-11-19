# frozen_string_literal: true

module PauseControl
  class ResumeWorker
    include ApplicationWorker
    include Search::Worker
    # There is no onward scheduling and this cron handles work from across the
    # application, so there's no useful context to add.
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    RESCHEDULE_DELAY = 1.second

    data_consistency :sticky
    idempotent!
    urgency :low

    def perform
      reschedule_job = false

      pause_strategies_workers.each do |strategy, workers|
        strategy_klass = Gitlab::SidekiqMiddleware::PauseControl.for(strategy)
        next if strategy_klass.should_pause?

        workers.each do |worker|
          next unless jobs_in_the_queue?(worker)

          queue_size = resume_processing!(worker)
          reschedule_job = true if queue_size.to_i > 0
        end
      end

      self.class.perform_in(RESCHEDULE_DELAY) if reschedule_job
    end

    private

    def jobs_in_the_queue?(worker)
      Gitlab::SidekiqMiddleware::PauseControl::PauseControlService.has_jobs_in_waiting_queue?(worker.to_s)
    end

    def resume_processing!(worker)
      Gitlab::SidekiqMiddleware::PauseControl::PauseControlService.resume_processing!(worker.to_s)
    end

    def pause_strategies_workers
      Gitlab::SidekiqMiddleware::PauseControl::WorkersMap.workers || []
    end
  end
end

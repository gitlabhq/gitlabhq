# frozen_string_literal: true

class RemoveScheduledFlushCounterIncrementsWorker < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  REMOVABLE_JOBS = %w[
    Gitlab::Counters::FlushStaleCounterIncrementsWorker
    Gitlab::Counters::FlushStaleCounterIncrementsCronWorker
  ]
  def up
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      job_to_remove = Sidekiq::Cron::Job.find('flush_stale_counter_increments_cron_worker')
      job_to_remove.destroy if job_to_remove
    end

    sidekiq_remove_jobs(job_klasses: REMOVABLE_JOBS)
  end

  def down
    # noop
  end
end

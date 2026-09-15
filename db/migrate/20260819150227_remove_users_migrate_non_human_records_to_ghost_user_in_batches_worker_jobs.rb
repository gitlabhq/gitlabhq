# frozen_string_literal: true

class RemoveUsersMigrateNonHumanRecordsToGhostUserInBatchesWorkerJobs < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    Users::MigrateNonHumanRecordsToGhostUserInBatchesWorker
  ]

  def up
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      # If the job has been scheduled via `sidekiq-cron`, we must also remove
      # it from the scheduled worker set using the key used to define the cron
      # schedule in config/schedule.yml or ee/config/schedule.yml.
      job_to_remove = Sidekiq::Cron::Job.find('users_migrate_non_human_records_to_ghost_user_in_batches_worker')
      job_to_remove.destroy if job_to_remove
    end

    # Removes scheduled instances from Sidekiq queues
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

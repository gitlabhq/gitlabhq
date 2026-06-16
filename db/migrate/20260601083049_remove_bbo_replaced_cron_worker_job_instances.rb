# frozen_string_literal: true

class RemoveBboReplacedCronWorkerJobInstances < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    Environments::AutoDeleteCronWorker
    Users::UnconfirmedSecondaryEmailsDeletionCronWorker
  ].freeze

  DEPRECATED_CRON_JOBS = %w[
    environments_auto_delete_cron_worker
    unconfirmed_secondary_emails_deletion_cron_worker
  ].freeze

  def up
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      DEPRECATED_CRON_JOBS.each do |cron_job_name|
        job_to_remove = Sidekiq::Cron::Job.find(cron_job_name)
        job_to_remove.destroy if job_to_remove
      end
    end

    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

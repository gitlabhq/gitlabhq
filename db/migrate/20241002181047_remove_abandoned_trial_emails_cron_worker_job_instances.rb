# frozen_string_literal: true

class RemoveAbandonedTrialEmailsCronWorkerJobInstances < Gitlab::Database::Migration[2.2]
  DEPRECATED_JOB_CLASSES = %w[Emails::AbandonedTrialEmailsCronWorker]

  milestone '17.5'
  disable_ddl_transaction!

  def up
    # If the job has been scheduled via `sidekiq-cron`, we must also remove
    # it from the scheduled worker set using the key used to define the cron
    # schedule in config/initializers/1_settings.rb.
    # See the key from removal in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149709
    job_to_remove = Sidekiq::Cron::Job.find('abandoned_trial_emails')
    # The job may be removed entirely:
    job_to_remove.destroy if job_to_remove

    # Removes scheduled instances from Sidekiq queues
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

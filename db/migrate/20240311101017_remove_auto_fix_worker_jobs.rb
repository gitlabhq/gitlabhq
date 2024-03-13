# frozen_string_literal: true

class RemoveAutoFixWorkerJobs < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  def up
    job_to_remove = Sidekiq::Cron::Job.find('security_auto_fix')

    job_to_remove.destroy if job_to_remove
    job_to_remove.disable! if job_to_remove

    sidekiq_remove_jobs(job_klasses: ['Security::AutoFixWorker'])
  end

  def down
    # no-op: removing jobs from sidekiq queue cannot be reversible.
  end
end

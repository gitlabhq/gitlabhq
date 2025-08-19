# frozen_string_literal: true

class RemoveLogDestroyWorkerJobs < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    LogDestroyWorker
  ]

  def up
    # Removes scheduled instances from Sidekiq queues
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

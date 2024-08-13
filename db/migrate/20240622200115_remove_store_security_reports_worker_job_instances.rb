# frozen_string_literal: true

class RemoveStoreSecurityReportsWorkerJobInstances < Gitlab::Database::Migration[2.2]
  DEPRECATED_JOB_CLASSES = %w[
    StoreSecurityReportsWorker
  ]

  disable_ddl_transaction!

  milestone '17.3'

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

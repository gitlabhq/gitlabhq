# frozen_string_literal: true

class RemovePackagesCacheDestroyOrphanEntriesWorkers < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    VirtualRegistries::Packages::Cache::DestroyOrphanEntriesWorker
  ]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

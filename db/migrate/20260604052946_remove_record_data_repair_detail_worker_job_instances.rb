# frozen_string_literal: true

class RemoveRecordDataRepairDetailWorkerJobInstances < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    ContainerRegistry::RecordDataRepairDetailWorker
  ]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

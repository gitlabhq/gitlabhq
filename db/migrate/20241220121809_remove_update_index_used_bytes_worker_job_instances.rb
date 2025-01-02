# frozen_string_literal: true

class RemoveUpdateIndexUsedBytesWorkerJobInstances < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  DEPRECATED_JOB_CLASSES = %w[Search::Zoekt::UpdateIndexUsedBytesWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

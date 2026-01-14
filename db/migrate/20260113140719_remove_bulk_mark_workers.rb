# frozen_string_literal: true

class RemoveBulkMarkWorkers < Gitlab::Database::Migration[2.3]
  DEPRECATED_JOB_CLASSES = %w[
    Geo::BulkMarkPendingBatchWorker
    Geo::BulkMarkVerificationPendingBatchWorker
  ]

  disable_ddl_transaction!
  milestone '18.9'

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

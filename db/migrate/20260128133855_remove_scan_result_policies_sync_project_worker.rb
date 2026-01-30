# frozen_string_literal: true

class RemoveScanResultPoliciesSyncProjectWorker < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  DEPRECATED_JOB_CLASSES = %w[Security::ScanResultPolicies::SyncProjectWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

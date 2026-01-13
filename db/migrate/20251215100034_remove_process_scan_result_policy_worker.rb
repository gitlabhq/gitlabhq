# frozen_string_literal: true

class RemoveProcessScanResultPolicyWorker < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  DEPRECATED_JOB_CLASSES = %w[Security::ProcessScanResultPolicyWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end

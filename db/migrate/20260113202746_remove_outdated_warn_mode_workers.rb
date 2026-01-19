# frozen_string_literal: true

class RemoveOutdatedWarnModeWorkers < Gitlab::Database::Migration[2.3]
  DEPRECATED_JOB_CLASSES = %w[
    Security::ScanResultPolicies::CreateProjectWarnModeAuditEventsWorker
    Security::ScanResultPolicies::CreateWarnModeAuditEventsWorker
    Security::ScanResultPolicies::RecreateProjectWarnModeAuditEventsWorker
  ]

  disable_ddl_transaction!
  milestone '18.9'

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down; end
end

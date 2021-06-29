# frozen_string_literal: true

class RenameSyncSecurityReportApprovalRulesSidekiqQueue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'sync_security_reports_to_report_approval_rules', to: 'ci_sync_reports_to_report_approval_rules' # rubocop:disable Migration/SidekiqQueueMigrate
  end

  def down
    sidekiq_queue_migrate 'ci_sync_reports_to_report_approval_rules', to: 'sync_security_reports_to_report_approval_rules' # rubocop:disable Migration/SidekiqQueueMigrate
  end
end

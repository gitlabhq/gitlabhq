# frozen_string_literal: true

class MigrateSyncSecurityReportsToReportApprovalRulesSidekiqQueue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'pipeline_default:sync_security_reports_to_report_approval_rules',
                          to: 'security_scans:sync_security_reports_to_report_approval_rules'
  end

  def down
    sidekiq_queue_migrate 'security_scans:sync_security_reports_to_report_approval_rules',
                          to: 'pipeline_default:sync_security_reports_to_report_approval_rules'
  end
end

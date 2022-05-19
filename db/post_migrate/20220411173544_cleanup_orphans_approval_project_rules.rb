# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanupOrphansApprovalProjectRules < Gitlab::Database::Migration[1.0]
  class ApprovalProjectRule < ActiveRecord::Base
    self.table_name = 'approval_project_rules'
  end

  def up
    return unless Gitlab.ee?

    ApprovalProjectRule.reset_column_information

    logger = ::Gitlab::BackgroundMigration::Logger.build
    records_ids = []

    # Related enum: report_type: { vulnerability: 1, license_scanning: 2, code_coverage: 3, scan_finding: 4 }
    ApprovalProjectRule.where(report_type: 4)
      .joins("LEFT JOIN security_orchestration_policy_configurations
              ON approval_project_rules.project_id = security_orchestration_policy_configurations.project_id")
      .where(security_orchestration_policy_configurations: { project_id: nil }).each do |record|
      records_ids << record.id
      logger.info(
        message: "CleanupOrphansApprovalProjectRules with record id: #{record.id}",
        class: ApprovalProjectRule.name,
        attributes: record.attributes
      )
    end

    ApprovalProjectRule.where(id: records_ids).delete_all
  end

  def down
    # no-op
  end
end

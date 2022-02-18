# frozen_string_literal: true

class AddSeverityLevelToMergeRequestsComplianceViolations < Gitlab::Database::Migration[1.0]
  def change
    add_column :merge_requests_compliance_violations, :severity_level, :integer, limit: 2, null: false, default: 0
  end
end

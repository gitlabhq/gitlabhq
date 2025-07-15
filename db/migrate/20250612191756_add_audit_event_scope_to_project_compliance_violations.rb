# frozen_string_literal: true

class AddAuditEventScopeToProjectComplianceViolations < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  # rubocop:disable Rails/NotNullColumn -- table is empty
  def change
    add_column :project_compliance_violations, :audit_event_table_name, :smallint, null: false
  end
  # rubocop:enable Rails/NotNullColumn
end

# frozen_string_literal: true

class AddForeignKeysForPendingIssueEscalations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :incident_management_pending_issue_escalations,
      :incident_management_escalation_rules,
      column: :rule_id

    add_concurrent_partitioned_foreign_key :incident_management_pending_issue_escalations,
      :issues,
      column: :issue_id
  end

  def down
    remove_foreign_key_if_exists :incident_management_pending_issue_escalations, :incident_management_escalation_rules, column: :rule_id
    remove_foreign_key_if_exists :incident_management_pending_issue_escalations, :issues, column: :issue_id
  end
end

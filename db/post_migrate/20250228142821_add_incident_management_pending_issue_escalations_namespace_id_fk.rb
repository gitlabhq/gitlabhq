# frozen_string_literal: true

class AddIncidentManagementPendingIssueEscalationsNamespaceIdFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :incident_management_pending_issue_escalations, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :incident_management_pending_issue_escalations, column: :namespace_id
    end
  end
end

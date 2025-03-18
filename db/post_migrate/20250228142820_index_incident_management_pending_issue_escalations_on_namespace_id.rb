# frozen_string_literal: true

class IndexIncidentManagementPendingIssueEscalationsOnNamespaceId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_incident_management_pending_issue_esc_on_namespace_id'

  def up
    add_concurrent_partitioned_index(:incident_management_pending_issue_escalations, :namespace_id, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(:incident_management_pending_issue_escalations, INDEX_NAME)
  end
end

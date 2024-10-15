# frozen_string_literal: true

class AddIncidentManagementPendingAlertEscalationsProjectIdFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.5'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :incident_management_pending_alert_escalations, :projects,
      column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :incident_management_pending_alert_escalations, column: :project_id
    end
  end
end

# frozen_string_literal: true

class AddIncidentManagementPendingAlertEscProjectIdFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :incident_management_pending_alert_escalations, :projects,
      column: :project_id, on_delete: :cascade, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :incident_management_pending_alert_escalations, column: :project_id,
        reverse_lock_order: true
    end
  end
end

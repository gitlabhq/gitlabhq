# frozen_string_literal: true

class RemoveIncidentManagementPendingAlertEscProjectIdFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.6'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_rails_2bbafb00ef'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:incident_management_pending_alert_escalations, :projects, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_partitioned_foreign_key :incident_management_pending_alert_escalations, :projects,
      column: :project_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end

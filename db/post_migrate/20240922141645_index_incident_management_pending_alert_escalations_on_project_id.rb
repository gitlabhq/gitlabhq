# frozen_string_literal: true

class IndexIncidentManagementPendingAlertEscalationsOnProjectId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_incident_management_pending_alert_escalations_on_project_id'

  def up
    add_concurrent_partitioned_index :incident_management_pending_alert_escalations, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :incident_management_pending_alert_escalations, INDEX_NAME
  end
end

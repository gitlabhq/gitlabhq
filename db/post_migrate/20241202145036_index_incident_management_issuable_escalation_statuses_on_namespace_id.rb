# frozen_string_literal: true

class IndexIncidentManagementIssuableEscalationStatusesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_incident_management_issuable_escalation_statuses_on_names'

  def up
    add_concurrent_index :incident_management_issuable_escalation_statuses, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :incident_management_issuable_escalation_statuses, INDEX_NAME
  end
end

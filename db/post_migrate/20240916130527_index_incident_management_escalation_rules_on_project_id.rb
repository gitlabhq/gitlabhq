# frozen_string_literal: true

class IndexIncidentManagementEscalationRulesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_incident_management_escalation_rules_on_project_id'

  def up
    add_concurrent_index :incident_management_escalation_rules, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :incident_management_escalation_rules, INDEX_NAME
  end
end

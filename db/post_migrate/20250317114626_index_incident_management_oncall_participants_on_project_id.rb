# frozen_string_literal: true

class IndexIncidentManagementOncallParticipantsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_incident_management_oncall_participants_on_project_id'

  def up
    add_concurrent_index :incident_management_oncall_participants, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :incident_management_oncall_participants, INDEX_NAME
  end
end

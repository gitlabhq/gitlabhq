# frozen_string_literal: true

class AddPartialIndexProjectIncidentManagementSettingsOnProjectIdAndSlaTimer < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_project_incident_management_settings_on_p_id_sla_timer'

  def up
    add_concurrent_index :project_incident_management_settings, :project_id,
      name: INDEX_NAME,
      where: 'sla_timer = TRUE'
  end

  def down
    remove_concurrent_index_by_name :project_incident_management_settings, name: INDEX_NAME
  end
end

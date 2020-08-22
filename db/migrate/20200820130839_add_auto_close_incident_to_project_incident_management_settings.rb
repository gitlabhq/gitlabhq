# frozen_string_literal: true

class AddAutoCloseIncidentToProjectIncidentManagementSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :project_incident_management_settings, :auto_close_incident, :boolean, default: true, null: false
  end

  def down
    remove_column :project_incident_management_settings, :auto_close_incident
  end
end

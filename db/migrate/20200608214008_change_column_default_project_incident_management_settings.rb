# frozen_string_literal: true

class ChangeColumnDefaultProjectIncidentManagementSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column_default(:project_incident_management_settings, :create_issue, from: true, to: false)
  end

  def down
    change_column_default(:project_incident_management_settings, :create_issue, from: false, to: true)
  end
end

# frozen_string_literal: true

class AddPagerDutyIntegrationColumnsToProjectIncidentManagementSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # limit constraints added in a separate migration:
  # 20200710130234_add_limit_constraints_to_project_incident_management_settings_token.rb
  def change
    add_column :project_incident_management_settings, :pagerduty_active, :boolean, null: false, default: false
    add_column :project_incident_management_settings, :encrypted_pagerduty_token, :binary, null: true
    add_column :project_incident_management_settings, :encrypted_pagerduty_token_iv, :binary, null: true
  end
end

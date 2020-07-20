# frozen_string_literal: true

class AddLimitConstraintsToProjectIncidentManagementSettingsToken < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_check_constraint :project_incident_management_settings, 'octet_length(encrypted_pagerduty_token) <= 255', 'pagerduty_token_length_constraint'
    add_check_constraint :project_incident_management_settings, 'octet_length(encrypted_pagerduty_token_iv) <= 12', 'pagerduty_token_iv_length_constraint'
  end

  def down
    remove_check_constraint :project_incident_management_settings, 'pagerduty_token_length_constraint'
    remove_check_constraint :project_incident_management_settings, 'pagerduty_token_iv_length_constraint'
  end
end

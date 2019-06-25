# frozen_string_literal: true

class EnableCreateIncidentIssuesByDefault < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_default_for :create_issue, from: false, to: true
    change_default_for :send_email, from: true, to: false
  end

  private

  def change_default_for(column, from:, to:)
    change_column_default :project_incident_management_settings,
      column, from: from, to: to
  end
end

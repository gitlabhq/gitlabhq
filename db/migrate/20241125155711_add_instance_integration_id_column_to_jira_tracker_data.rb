# frozen_string_literal: true

class AddInstanceIntegrationIdColumnToJiraTrackerData < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :jira_tracker_data, :instance_integration_id, :bigint
  end
end

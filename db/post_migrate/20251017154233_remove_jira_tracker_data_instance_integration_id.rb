# frozen_string_literal: true

class RemoveJiraTrackerDataInstanceIntegrationId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    remove_column :jira_tracker_data, :instance_integration_id
  end

  def down
    add_column :jira_tracker_data, :instance_integration_id, :bigint
  end
end

# frozen_string_literal: true

class AddProjectKeysToJiraTrackerData < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def change
    add_column :jira_tracker_data, :project_keys,
      :text,
      array: true,
      default: [],
      null: false
  end
end

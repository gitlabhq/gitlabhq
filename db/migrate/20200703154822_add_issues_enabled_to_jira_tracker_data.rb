# frozen_string_literal: true

class AddIssuesEnabledToJiraTrackerData < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :jira_tracker_data, :issues_enabled, :boolean, default: false, null: false
  end
end

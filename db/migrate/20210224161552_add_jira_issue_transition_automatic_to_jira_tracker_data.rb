# frozen_string_literal: true

class AddJiraIssueTransitionAutomaticToJiraTrackerData < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :jira_tracker_data, :jira_issue_transition_automatic, :boolean, null: false, default: false
  end
end

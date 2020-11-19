# frozen_string_literal: true

class AddVulnerabilitiesEnabledAndIssuetypeToJiraTrackerData < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20201105143312_add_text_limit_to_jira_tracker_data_issuetype.rb
  def change
    add_column :jira_tracker_data, :vulnerabilities_issuetype, :text
    add_column :jira_tracker_data, :vulnerabilities_enabled, :boolean, default: false, null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

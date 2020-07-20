# frozen_string_literal: true

class AddProjectKeyToJiraTrackerData < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20200619154528_add_text_limit_to_jira_tracker_data_project_key
  def change
    add_column :jira_tracker_data, :project_key, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

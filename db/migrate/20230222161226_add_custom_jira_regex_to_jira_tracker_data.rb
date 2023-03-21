# frozen_string_literal: true

class AddCustomJiraRegexToJiraTrackerData < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230222161954_add_text_limit_to_custom_jira_regex_fields.rb
  enable_lock_retries!
  def change
    add_column :jira_tracker_data, :jira_issue_prefix, :text
    add_column :jira_tracker_data, :jira_issue_regex, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

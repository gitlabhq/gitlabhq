# frozen_string_literal: true

class AddCustomizeJiraIssueEnabled < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :jira_tracker_data, :customize_jira_issue_enabled, :boolean, default: false, if_not_exists: false
  end
end

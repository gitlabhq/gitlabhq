# frozen_string_literal: true

class AddTextLimitToCustomJiraRegexFields < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :jira_tracker_data, :jira_issue_prefix, 255
    add_text_limit :jira_tracker_data, :jira_issue_regex, 255
  end

  def down
    remove_text_limit :jira_tracker_data, :jira_issue_regex
    remove_text_limit :jira_tracker_data, :jira_issue_prefix
  end
end

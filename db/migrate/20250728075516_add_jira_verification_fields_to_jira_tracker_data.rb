# frozen_string_literal: true

class AddJiraVerificationFieldsToJiraTrackerData < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :jira_tracker_data, :jira_check_enabled, :boolean, default: false, null: false, if_not_exists: true
      add_column :jira_tracker_data, :jira_assignee_check_enabled, :boolean, default: false, null: false,
        if_not_exists: true
      add_column :jira_tracker_data, :jira_status_check_enabled, :boolean, default: false, null: false,
        if_not_exists: true
      add_column :jira_tracker_data, :jira_exists_check_enabled, :boolean, default: false, null: false,
        if_not_exists: true
      add_column :jira_tracker_data, :jira_allowed_statuses_string, :text, if_not_exists: true
    end

    add_text_limit :jira_tracker_data, :jira_allowed_statuses_string, 1024
  end

  def down
    with_lock_retries do
      remove_column :jira_tracker_data, :jira_exists_check_enabled, if_not_exists: true
      remove_column :jira_tracker_data, :jira_allowed_statuses_string, if_not_exists: true
      remove_column :jira_tracker_data, :jira_status_check_enabled, if_not_exists: true
      remove_column :jira_tracker_data, :jira_assignee_check_enabled, if_not_exists: true
      remove_column :jira_tracker_data, :jira_check_enabled, if_not_exists: true
    end
  end
end

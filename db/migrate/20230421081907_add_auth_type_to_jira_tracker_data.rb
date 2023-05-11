# frozen_string_literal: true

class AddAuthTypeToJiraTrackerData < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def change
    add_column :jira_tracker_data, :jira_auth_type, :smallint, default: 0, null: false
  end
end

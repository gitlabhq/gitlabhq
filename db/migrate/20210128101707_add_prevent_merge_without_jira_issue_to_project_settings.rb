# frozen_string_literal: true

class AddPreventMergeWithoutJiraIssueToProjectSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_settings, :prevent_merge_without_jira_issue, :boolean, null: false, default: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_settings, :prevent_merge_without_jira_issue
    end
  end
end

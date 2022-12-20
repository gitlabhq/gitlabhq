# frozen_string_literal: true

class RemoveIndexToIssueAssigneesOnUserId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_issue_assignees_on_user_id"

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :issue_assignees, INDEX_NAME
  end

  def down
    add_concurrent_index :issue_assignees, [:user_id], name: INDEX_NAME
  end
end

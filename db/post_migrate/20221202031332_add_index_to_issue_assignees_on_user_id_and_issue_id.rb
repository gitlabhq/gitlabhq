# frozen_string_literal: true

class AddIndexToIssueAssigneesOnUserIdAndIssueId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_issue_assignees_on_user_id_and_issue_id"

  disable_ddl_transaction!

  def up
    add_concurrent_index :issue_assignees, [:user_id, :issue_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_assignees, INDEX_NAME
  end
end

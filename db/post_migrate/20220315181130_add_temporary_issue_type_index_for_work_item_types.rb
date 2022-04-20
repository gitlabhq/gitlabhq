# frozen_string_literal: true

class AddTemporaryIssueTypeIndexForWorkItemTypes < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_issues_on_issue_type_and_id'

  def up
    add_concurrent_index :issues, [:issue_type, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end

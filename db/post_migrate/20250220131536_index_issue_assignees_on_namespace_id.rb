# frozen_string_literal: true

class IndexIssueAssigneesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_assignees_on_namespace_id'

  def up
    add_concurrent_index :issue_assignees, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issue_assignees, INDEX_NAME
  end
end

# frozen_string_literal: true

class IndexEpicIssuesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_epic_issues_on_namespace_id'

  def up
    add_concurrent_index :epic_issues, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :epic_issues, INDEX_NAME
  end
end

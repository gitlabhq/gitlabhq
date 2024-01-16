# frozen_string_literal: true

class DropNamespaceIdIndexOnIssues < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_issues_on_namespace_id'

  disable_ddl_transaction!

  milestone '16.8'

  def up
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end

  def down
    add_concurrent_index :issues, :namespace_id, name: INDEX_NAME
  end
end

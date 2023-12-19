# frozen_string_literal: true

class AddIssueSearchDataNamespaceIdForeignKey < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_issue_search_data_on_namespace_id'

  def up
    add_concurrent_partitioned_index :issue_search_data, :namespace_id, name: INDEX_NAME
    add_concurrent_partitioned_foreign_key :issue_search_data, :namespaces,
      column: :namespace_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :issue_search_data, column: :namespace_id
    remove_concurrent_partitioned_index_by_name :issue_search_data, INDEX_NAME
  end
end

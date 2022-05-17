# frozen_string_literal: true

class RemoveTmpEmptyTraversalIdsChildNamespaceIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  CHILD_INDEX_NAME = 'tmp_index_namespaces_empty_traversal_ids_with_child_namespaces'

  def up
    remove_concurrent_index :namespaces, :id, name: CHILD_INDEX_NAME
  end

  def down
    where_sql = "parent_id IS NOT NULL AND traversal_ids = '{}'"
    add_concurrent_index :namespaces, :id, where: where_sql, name: CHILD_INDEX_NAME
  end
end

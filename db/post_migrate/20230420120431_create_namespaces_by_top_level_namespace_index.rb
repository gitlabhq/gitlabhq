# frozen_string_literal: true

class CreateNamespacesByTopLevelNamespaceIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_namespaces_namespaces_by_top_level_namespace'

  def up
    add_concurrent_index :namespaces, '(traversal_ids[1]), type, id', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end

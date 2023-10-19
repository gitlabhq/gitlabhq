# frozen_string_literal: true

class DropIndexBtreeNamespacesTraversalIds < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :namespaces
  INDEX_NAME = :index_btree_namespaces_traversal_ids

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :traversal_ids, name: INDEX_NAME
  end
end

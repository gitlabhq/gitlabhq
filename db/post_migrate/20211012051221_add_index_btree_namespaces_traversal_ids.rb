# frozen_string_literal: true

class AddIndexBtreeNamespacesTraversalIds < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_btree_namespaces_traversal_ids'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, :traversal_ids, using: :btree, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :namespaces, :traversal_ids, name: INDEX_NAME
  end
end

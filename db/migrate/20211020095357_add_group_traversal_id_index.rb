# frozen_string_literal: true

class AddGroupTraversalIdIndex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_namespaces_on_traversal_ids_for_groups'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, :traversal_ids, using: :gin, where: "type='Group'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end

# frozen_string_literal: true

class AddTraversalIdTypeGroupIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_namespaces_on_traversal_ids_for_groups_btree'

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventIndexCreation
  def up
    add_concurrent_index :namespaces, :traversal_ids, using: :btree, where: "type='Group'", name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end

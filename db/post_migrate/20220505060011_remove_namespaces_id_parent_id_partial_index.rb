# frozen_string_literal: true

class RemoveNamespacesIdParentIdPartialIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NAME = 'index_namespaces_id_parent_id_is_null'

  def up
    remove_concurrent_index :namespaces, :id, name: NAME
  end

  def down
    add_concurrent_index :namespaces, :id, where: 'parent_id IS NULL', name: NAME
  end
end

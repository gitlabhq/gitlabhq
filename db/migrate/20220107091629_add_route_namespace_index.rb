# frozen_string_literal: true

class AddRouteNamespaceIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!
  INDEX_NAME = 'index_routes_on_namespace_id'

  def up
    add_concurrent_index :routes, :namespace_id, unique: true, name: INDEX_NAME
    add_concurrent_foreign_key :routes, :namespaces, column: :namespace_id, on_delete: :nullify, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :routes, column: :namespace_id
    end

    remove_concurrent_index_by_name :routes, INDEX_NAME
  end
end

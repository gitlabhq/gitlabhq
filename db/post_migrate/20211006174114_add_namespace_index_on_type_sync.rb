# frozen_string_literal: true

class AddNamespaceIndexOnTypeSync < Gitlab::Database::Migration[1.0]
  FULL_INDEX_NAME = 'index_namespaces_on_type_and_id'
  PARTIAL_INDEX_NAME = 'index_namespaces_on_type_and_id_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, [:type, :id], name: FULL_INDEX_NAME

    remove_concurrent_index_by_name :namespaces, name: PARTIAL_INDEX_NAME
  end

  def down
    add_concurrent_index(:namespaces, [:type, :id], where: 'type IS NOT NULL', name: PARTIAL_INDEX_NAME)

    remove_concurrent_index_by_name :namespaces, name: FULL_INDEX_NAME
  end
end

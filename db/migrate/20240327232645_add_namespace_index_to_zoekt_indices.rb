# frozen_string_literal: true

class AddNamespaceIndexToZoektIndices < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  INDEX_NAME = 'index_zoekt_indices_on_namespace_id'

  def up
    add_concurrent_index :zoekt_indices, [:namespace_id, :zoekt_enabled_namespace_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :zoekt_indices, INDEX_NAME
  end
end

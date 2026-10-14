# frozen_string_literal: true

class AddStatusIdIndexToNamespaceStatePropagations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  INDEX_NAME = 'idx_namespace_state_propagations_on_status_id'

  def up
    add_concurrent_index :namespace_state_propagations, [:status, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespace_state_propagations, INDEX_NAME
  end
end

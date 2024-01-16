# frozen_string_literal: true

class CreateZoektIndices < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  ZOEKT_NODE_ID_INDEX_NAME = 'index_zoekt_indices_on_zoekt_node_id'
  STATE_INDEX_NAME = 'index_zoekt_indices_on_state'
  ZOEKT_ENABLED_NAMESPACE_ID_AND_NODE_ID_INDEX_NAME = 'u_zoekt_indices_zoekt_enabled_namespace_id_and_zoekt_node_id'

  def change
    create_table :zoekt_indices do |t|
      t.bigint :zoekt_enabled_namespace_id, null: true
      t.bigint :zoekt_node_id, null: false
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :state, null: false, default: 0, limit: 2

      t.index :state, name: STATE_INDEX_NAME, using: :btree
      t.index :zoekt_node_id, name: ZOEKT_NODE_ID_INDEX_NAME, using: :btree
      t.index [:zoekt_enabled_namespace_id, :zoekt_node_id],
        name: ZOEKT_ENABLED_NAMESPACE_ID_AND_NODE_ID_INDEX_NAME, unique: true, using: :btree
    end
  end
end

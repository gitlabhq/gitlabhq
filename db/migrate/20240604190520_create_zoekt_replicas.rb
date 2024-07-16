# frozen_string_literal: true

class CreateZoektReplicas < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  STATE_INDEX_NAME = 'index_zoekt_replicas_on_state'

  def change
    create_table :zoekt_replicas do |t|
      t.bigint :zoekt_enabled_namespace_id, null: false
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :state, null: false, default: 0, limit: 2

      t.index :state, name: STATE_INDEX_NAME, using: :btree
    end

    add_column :zoekt_indices, :zoekt_replica_id, :bigint, null: true
  end
end

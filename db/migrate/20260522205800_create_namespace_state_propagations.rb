# frozen_string_literal: true

class CreateNamespaceStatePropagations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  STATUS_CREATED_AT_INDEX_NAME = "idx_namespace_state_propagations_on_status_created_at"
  UNIQUE_PARTIAL_INDEX_NAME = "idx_namespace_state_propagations_unique_pending_processing"
  NAMESPACE_ID_INDEX_NAME = "idx_namespace_state_propagations_on_namespace_id"

  def up
    create_table :namespace_state_propagations, if_not_exists: true do |t|
      t.bigint :namespace_id, null: false
      t.datetime_with_timezone :started_at
      t.timestamps_with_timezone null: false
      t.integer :source_state, limit: 2, null: false
      t.integer :target_state, limit: 2, null: false
      t.integer :status, limit: 2, null: false, default: 0

      t.index :namespace_id, name: NAMESPACE_ID_INDEX_NAME
      t.index [:status, :created_at], name: STATUS_CREATED_AT_INDEX_NAME
      t.index [:namespace_id, :target_state],
        unique: true,
        where: "(status IN (0, 1))",
        name: UNIQUE_PARTIAL_INDEX_NAME
    end

    add_concurrent_foreign_key :namespace_state_propagations, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end

  def down
    drop_table :namespace_state_propagations
  end
end

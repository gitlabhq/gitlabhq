# frozen_string_literal: true

class CreateEnabledFoundationalFlows < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    create_table :enabled_foundational_flows, if_not_exists: true do |t|
      t.bigint :namespace_id
      t.bigint :project_id
      t.bigint :catalog_item_id, null: false

      t.timestamps_with_timezone null: false
    end

    add_concurrent_index :enabled_foundational_flows, :namespace_id
    add_concurrent_index :enabled_foundational_flows, :project_id
    add_concurrent_index :enabled_foundational_flows, :catalog_item_id
    add_concurrent_index :enabled_foundational_flows,
      [:namespace_id, :catalog_item_id],
      unique: true,
      where: 'namespace_id IS NOT NULL',
      name: 'idx_enabled_flows_on_namespace_catalog_item'
    add_concurrent_index :enabled_foundational_flows,
      [:project_id, :catalog_item_id],
      unique: true,
      where: 'project_id IS NOT NULL',
      name: 'idx_enabled_flows_on_project_catalog_item'

    add_multi_column_not_null_constraint(:enabled_foundational_flows, :namespace_id, :project_id)

    add_concurrent_foreign_key :enabled_foundational_flows, :ai_catalog_items, column: :catalog_item_id,
      on_delete: :cascade
  end

  def down
    drop_table :enabled_foundational_flows
  end
end

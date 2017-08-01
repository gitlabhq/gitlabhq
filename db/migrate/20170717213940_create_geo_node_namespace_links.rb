class CreateGeoNodeNamespaceLinks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :geo_node_namespace_links do |t|
      t.references :geo_node, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.integer :namespace_id, null: false
    end

    add_timestamps_with_timezone :geo_node_namespace_links

    add_concurrent_foreign_key :geo_node_namespace_links, :namespaces, column: :namespace_id, on_delete: :cascade

    add_concurrent_index :geo_node_namespace_links, [:geo_node_id, :namespace_id], unique: true
  end

  def down
    remove_foreign_key :geo_node_namespace_links, column: :namespace_id

    if index_exists?(:geo_node_namespace_links, [:geo_node_id, :namespace_id])
      remove_concurrent_index :geo_node_namespace_links, [:geo_node_id, :namespace_id]
    end

    drop_table :geo_node_namespace_links
  end
end

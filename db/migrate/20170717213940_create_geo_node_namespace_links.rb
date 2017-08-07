class CreateGeoNodeNamespaceLinks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :geo_node_namespace_links do |t|
      t.references :geo_node, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.references :namespace, foreign_key: { on_delete: :cascade }, null: false

      t.index [:geo_node_id, :namespace_id], unique: true
    end

    add_timestamps_with_timezone :geo_node_namespace_links
  end
end

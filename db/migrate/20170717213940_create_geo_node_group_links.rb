class CreateGeoNodeGroupLinks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_node_group_links do |t|
      t.references :geo_node, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.integer :group_id, index: true, null: false
    end

    add_timestamps_with_timezone :geo_node_group_links

    add_foreign_key :geo_node_group_links, :namespaces, column: :group_id, on_delete: :cascade
  end
end

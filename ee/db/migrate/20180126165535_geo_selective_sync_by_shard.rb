class GeoSelectiveSyncByShard < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :geo_nodes, :selective_sync_type, :string
    add_column :geo_nodes, :selective_sync_shards, :text

    # Nodes with associated namespaces should be set to 'namespaces'
    connection.execute(<<~SQL)
      UPDATE geo_nodes
      SET selective_sync_type = 'namespaces'
      WHERE id IN(
        SELECT DISTINCT geo_node_id
        FROM geo_node_namespace_links
      )
    SQL
  end

  def down
    remove_column :geo_nodes, :selective_sync_type
    remove_column :geo_nodes, :selective_sync_shards
  end
end

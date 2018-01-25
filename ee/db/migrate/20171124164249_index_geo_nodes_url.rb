class IndexGeoNodesUrl < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :geo_nodes, :url, unique: true
  end

  def down
    remove_concurrent_index :geo_nodes, :url, unique: true
  end
end

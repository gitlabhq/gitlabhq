class RemoveGeoNodesUrlPartColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_column :geo_nodes, :schema, :string
    remove_column :geo_nodes, :host, :string
    remove_column :geo_nodes, :port, :integer
    remove_column :geo_nodes, :relative_url_root, :string
  end

  def down
    add_column :geo_nodes, :schema, :string
    add_column :geo_nodes, :host, :string
    add_column :geo_nodes, :port, :integer
    add_column :geo_nodes, :relative_url_root, :string

    add_concurrent_index :geo_nodes, :host
  end
end

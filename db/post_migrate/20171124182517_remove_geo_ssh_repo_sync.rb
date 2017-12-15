class RemoveGeoSshRepoSync < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  GeoNode = Class.new(ActiveRecord::Base)
  Key = Class.new(ActiveRecord::Base)

  disable_ddl_transaction!

  def up
    Key.where(id: GeoNode.all.select(:geo_node_key_id)).delete_all

    remove_column :geo_nodes, :clone_protocol
    remove_column :geo_nodes, :geo_node_key_id
  end

  def down
    add_column :geo_nodes, :geo_node_key_id, :integer
    add_column_with_default :geo_nodes, :clone_protocol, :string, default: 'http', allow_null: false
  end
end

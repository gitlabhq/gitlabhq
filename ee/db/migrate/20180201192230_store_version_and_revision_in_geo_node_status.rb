class StoreVersionAndRevisionInGeoNodeStatus < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :version, :string
    add_column :geo_node_statuses, :revision, :string
  end
end

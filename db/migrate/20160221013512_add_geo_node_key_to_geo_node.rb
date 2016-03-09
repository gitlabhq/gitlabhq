class AddGeoNodeKeyToGeoNode < ActiveRecord::Migration
  def change
    change_table :geo_nodes do |t|
      t.belongs_to :geo_node_key, index: true
    end
  end
end

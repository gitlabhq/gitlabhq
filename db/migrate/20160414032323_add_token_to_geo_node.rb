class AddTokenToGeoNode < ActiveRecord::Migration
  def change
    add_column :geo_nodes, :token, :string
  end
end

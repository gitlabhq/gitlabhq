class AddTokenToGeoNode < ActiveRecord::Migration
  def change
    add_column :geo_nodes, :token, :string

    # Add token to existing nodes
    GeoNode.where(token: nil).each do |node|
      node.token = SecureRandom.hex(20)
      node.save!
    end
  end
end

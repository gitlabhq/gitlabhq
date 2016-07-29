class AddDoorkeeperApplicationToGeoNode < ActiveRecord::Migration
  def change
    change_table :geo_nodes do |t|
      t.belongs_to :oauth_application
    end
  end
end

class CreateGeoNodes < ActiveRecord::Migration
  def change
    create_table :geo_nodes do |t|
      t.string :host
      t.string :relative_url_root
      t.boolean :primary
    end
  end
end

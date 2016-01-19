class CreateGeoNodes < ActiveRecord::Migration
  def change
    create_table :geo_nodes do |t|
      t.string :schema
      t.string :host, index: true
      t.integer :port
      t.string :relative_url_root
      t.boolean :primary, index: true
    end
  end
end

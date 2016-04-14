class AddSystemHookToGeoNode < ActiveRecord::Migration
  def change
    change_table :geo_nodes do |t|
      t.references :system_hook
    end
  end
end

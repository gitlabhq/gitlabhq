class AddActiveToService < ActiveRecord::Migration
  def change
    add_column :services, :active, :boolean, default: false, null: false
  end
end

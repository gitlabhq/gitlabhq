class AddTimeZoneNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :time_zone_name, :string, default: 'UTC', null: false
  end
end

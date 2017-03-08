class AddHeaderLogosToAppearances < ActiveRecord::Migration
  def change
    add_column :appearances, :dark_logo, :string
    add_column :appearances, :light_logo, :string
  end
end

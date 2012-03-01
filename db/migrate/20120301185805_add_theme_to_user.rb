class AddThemeToUser < ActiveRecord::Migration
  def change
    add_column :users, :theme_id, :integer, :null => false, :default => 1

  end
end

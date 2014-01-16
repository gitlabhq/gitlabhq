class AddVisibilityLevelToUsers < ActiveRecord::Migration
  def change
    add_column :users, :visibility_level, :integer, :null => false
  end
end

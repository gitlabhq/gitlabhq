class AddUserPermissions < ActiveRecord::Migration
  def up
    add_column :users, :can_create_group, :boolean, default: true, null: false
    add_column :users, :can_create_team, :boolean, default: true, null: false
  end

  def down
    remove_column :users, :can_create_group
    remove_column :users, :can_create_team
  end
end

class AddCreateGlobalProjectPermission < ActiveRecord::Migration
  def up
    add_column :users, :can_create_global_project, :boolean, default: false, null: false
    User.admins.update_all(can_create_global_project: true)
  end

  def down
    remove_column :users, :can_create_global_project
  end
end

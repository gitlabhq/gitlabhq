class MigrateToNewRights < ActiveRecord::Migration
  def up
    # Repository access
    UsersProject.update_all("repo_access = 2", :write => true)
    UsersProject.update_all("repo_access = 1", :read => true, :write => false)

    # Project access
    UsersProject.update_all("project_access = 1", :read => true, :write => false, :admin => false)
    UsersProject.update_all("project_access = 2", :read => true, :write => true, :admin => false)
    UsersProject.update_all("project_access = 3", :read => true, :write => true, :admin => true)

    # Remove old fields
    remove_column :users_projects, :read
    remove_column :users_projects, :write
    remove_column :users_projects, :admin
  end

  def down
  end
end

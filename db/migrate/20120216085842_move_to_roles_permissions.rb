class MoveToRolesPermissions < ActiveRecord::Migration
  def up
    repo_n = 0
    repo_r = 1
    repo_rw = 2
    project_rwa = 3


    # Build masters and reset repo_access
    UsersProject.update_all({:project_access => UsersProject::MASTER, :repo_access => 99 }, ["project_access = ?", project_rwa])

    # Build other roles based on repo access
    UsersProject.update_all ["project_access = ?", UsersProject::DEVELOPER], ["repo_access = ?", repo_rw]
    UsersProject.update_all ["project_access = ?", UsersProject::REPORTER], ["repo_access = ?", repo_r]
    UsersProject.update_all ["project_access = ?", UsersProject::GUEST], ["repo_access = ?", repo_n]

    remove_column :users_projects, :repo_access
  end

  def down
  end
end

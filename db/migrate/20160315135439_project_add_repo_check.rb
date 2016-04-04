class ProjectAddRepoCheck < ActiveRecord::Migration
  def change
    add_column :projects, :last_repo_check_failed, :boolean, default: false
    add_column :projects, :last_repo_check_at, :datetime
  end
end

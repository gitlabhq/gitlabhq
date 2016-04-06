class ProjectAddRepositoryCheck < ActiveRecord::Migration
  def change
    add_column :projects, :last_repository_check_failed, :boolean, default: false
    add_column :projects, :last_repository_check_at, :datetime
  end
end

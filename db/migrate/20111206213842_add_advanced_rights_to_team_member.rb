class AddAdvancedRightsToTeamMember < ActiveRecord::Migration
  def change
    add_column :users_projects, :repo_access, :integer, :default => 0, :null => false
    add_column :users_projects, :project_access, :integer, :default => 0, :null => false
  end
end

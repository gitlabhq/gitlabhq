class AddProjectIdToCiCommit < ActiveRecord::Migration
  def up
    add_column :ci_commits, :gl_project_id, :integer
  end
end

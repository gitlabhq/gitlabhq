class AddProjectIdToCiCommit < ActiveRecord::Migration[4.2]
  def up
    add_column :ci_commits, :gl_project_id, :integer
  end
end

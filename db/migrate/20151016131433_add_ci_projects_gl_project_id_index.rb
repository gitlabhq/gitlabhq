class AddCiProjectsGlProjectIdIndex < ActiveRecord::Migration
  def change
    add_index :ci_commits, :gl_project_id
  end
end

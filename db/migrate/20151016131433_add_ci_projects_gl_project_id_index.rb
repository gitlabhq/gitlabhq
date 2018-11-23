# rubocop:disable all
class AddCiProjectsGlProjectIdIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :ci_commits, :gl_project_id
  end
end

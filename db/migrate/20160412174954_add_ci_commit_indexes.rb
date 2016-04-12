class AddCiCommitIndexes < ActiveRecord::Migration
  def change
    add_index :ci_commits, [:gl_project_id, :sha]
    add_index :ci_commits, [:gl_project_id, :status]
    add_index :ci_commits, [:status]
  end
end

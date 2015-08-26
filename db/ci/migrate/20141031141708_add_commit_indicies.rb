class AddCommitIndicies < ActiveRecord::Migration
  def change
    add_index :commits, :project_id
    add_index :commits, :sha, length: 6
    add_index :commits, [:project_id, :sha]
    add_index :builds, :commit_id
    add_index :builds, [:project_id, :commit_id]
  end
end

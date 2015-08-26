class AddCommittedAtToCommits < ActiveRecord::Migration
  def up
    add_column :commits, :committed_at, :timestamp
    add_index :commits, [:project_id, :committed_at]
  end
end

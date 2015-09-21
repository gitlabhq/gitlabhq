class AddIndexForCommittedAtAndId < ActiveRecord::Migration
  def change
    add_index :ci_commits, [:project_id, :committed_at, :id]
  end
end

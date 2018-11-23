# rubocop:disable all
class AddIndexForCommittedAtAndId < ActiveRecord::Migration[4.2]
  def change
    add_index :ci_commits, [:project_id, :committed_at, :id]
  end
end

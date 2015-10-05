class AddIndexForBuilds < ActiveRecord::Migration
  def up
    add_index :ci_builds, [:commit_id, :stage_idx, :created_at]
  end
end

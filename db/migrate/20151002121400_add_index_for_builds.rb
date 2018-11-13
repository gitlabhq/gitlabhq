# rubocop:disable all
class AddIndexForBuilds < ActiveRecord::Migration[4.2]
  def up
    add_index :ci_builds, [:commit_id, :stage_idx, :created_at]
  end
end

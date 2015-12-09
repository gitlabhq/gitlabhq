class AddMergeWhenBuildSucceedsToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :merge_params, :text
    add_column :merge_requests, :merge_when_build_succeeds, :boolean, default: false, null: false
    add_column :merge_requests, :merge_user_id, :integer
  end
end

class AddMilestoneIdToMergeRequests < ActiveRecord::Migration
  def change
    add_column :merge_requests, :milestone_id, :integer, :null => true
  end
end

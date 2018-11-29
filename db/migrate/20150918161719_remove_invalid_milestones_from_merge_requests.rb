class RemoveInvalidMilestonesFromMergeRequests < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE merge_requests SET milestone_id = NULL where milestone_id NOT IN (SELECT id FROM milestones)")
  end
end

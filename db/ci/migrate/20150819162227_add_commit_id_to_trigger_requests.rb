class AddCommitIdToTriggerRequests < ActiveRecord::Migration
  def up
    add_column :trigger_requests, :commit_id, :integer
  end

  def down
  end
end

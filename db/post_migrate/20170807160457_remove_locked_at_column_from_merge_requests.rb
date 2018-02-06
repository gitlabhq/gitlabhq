class RemoveLockedAtColumnFromMergeRequests < ActiveRecord::Migration
  DOWNTIME = false

  def up
    remove_column :merge_requests, :locked_at
  end

  def down
    add_column :merge_requests, :locked_at, :datetime_with_timezone
  end
end

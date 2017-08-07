class RemoveLockedAtColumnFromMergeRequests < ActiveRecord::Migration
  DOWNTIME = false

  def up
    remove_column :merge_requests, :locked_at
  end

  def down
    # nothing to do to recover the values
  end
end

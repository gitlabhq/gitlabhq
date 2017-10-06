class AddDiscussionLockedToIssuable < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column(:merge_requests, :discussion_locked, :boolean)
    add_column(:issues, :discussion_locked, :boolean)
  end

  def down
    remove_column(:merge_requests, :discussion_locked)
    remove_column(:issues, :discussion_locked)
  end
end

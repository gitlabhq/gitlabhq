class RemoveClosedFromMergeRequest < ActiveRecord::Migration
  def up
    remove_column :merge_requests, :closed
  end

  def down
    add_column :merge_requests, :closed, :boolean
  end
end

class AddConflictsToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :conflicts, :text
  end
end

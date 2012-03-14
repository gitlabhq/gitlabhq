class AddMergedToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :merged, :true, :null => false, :default => false
  end
end

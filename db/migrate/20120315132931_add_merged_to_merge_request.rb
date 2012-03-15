class AddMergedToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :merged, :boolean, :null => false, :default => false
  end
end

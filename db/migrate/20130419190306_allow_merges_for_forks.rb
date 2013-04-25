class AllowMergesForForks < ActiveRecord::Migration

  def self.up
    add_column :merge_requests, :target_project_id, :integer, :null => false
    MergeRequest.connection.execute("update merge_requests set target_project_id=project_id")
    rename_column :merge_requests, :project_id, :source_project_id
  end

  def self.down
    remove_column :merge_requests, :target_project_id
    rename_column :merge_requests, :source_project_id,:project_id
  end

end

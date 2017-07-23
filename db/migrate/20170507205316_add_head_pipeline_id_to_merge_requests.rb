class AddHeadPipelineIdToMergeRequests < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :merge_requests, :head_pipeline_id, :integer
  end
end

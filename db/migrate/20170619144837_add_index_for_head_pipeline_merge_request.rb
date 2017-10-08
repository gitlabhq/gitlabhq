class AddIndexForHeadPipelineMergeRequest < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, :head_pipeline_id
  end

  def down
    remove_concurrent_index :merge_requests, :head_pipeline_id if index_exists?(:merge_requests, :head_pipeline_id)
  end
end

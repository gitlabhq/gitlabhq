class MigrateUpdateHeadPipelineForMergeRequestSidekiqQueue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'pipeline_default:update_head_pipeline_for_merge_request',
      to: 'pipeline_processing:update_head_pipeline_for_merge_request'
  end

  def down
    sidekiq_queue_migrate 'pipeline_processing:update_head_pipeline_for_merge_request',
      to: 'pipeline_default:update_head_pipeline_for_merge_request'
  end
end

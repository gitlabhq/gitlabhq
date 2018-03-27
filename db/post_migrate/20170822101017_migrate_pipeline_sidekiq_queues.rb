class MigratePipelineSidekiqQueues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'build', to: 'pipeline_default'
    sidekiq_queue_migrate 'pipeline', to: 'pipeline_default'
  end

  def down
    sidekiq_queue_migrate 'pipeline_default', to: 'pipeline'
    sidekiq_queue_migrate 'pipeline_processing', to: 'pipeline'
    sidekiq_queue_migrate 'pipeline_hooks', to: 'pipeline'
    sidekiq_queue_migrate 'pipeline_cache', to: 'pipeline'
  end
end

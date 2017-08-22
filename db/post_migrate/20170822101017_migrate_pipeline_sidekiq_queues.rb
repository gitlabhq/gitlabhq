class MigratePipelineSidekiqQueues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'build', to: 'pipeline_default'
    sidekiq_queue_migrate 'pipeline', to: 'pipeline_default'
  end

  def down
    sidekiq_queue_migrate 'pipeline_default', to: 'pipeline'
  end
end

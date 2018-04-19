class MigrateCreateTraceArtifactSidekiqQueue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'pipeline_default:create_trace_artifact', to: 'pipeline_background:archive_trace'
  end

  def down
    sidekiq_queue_migrate 'pipeline_background:archive_trace', to: 'pipeline_default:create_trace_artifact'
  end
end

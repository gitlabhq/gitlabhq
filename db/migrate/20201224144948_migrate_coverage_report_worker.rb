# frozen_string_literal: true

class MigrateCoverageReportWorker < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'ci_pipelines_create_artifact', to: 'ci_pipeline_artifacts_coverage_report' # rubocop:disable Migration/SidekiqQueueMigrate
  end

  def down
    sidekiq_queue_migrate 'ci_pipeline_artifacts_coverage_report', to: 'ci_pipelines_create_artifact' # rubocop:disable Migration/SidekiqQueueMigrate
  end
end

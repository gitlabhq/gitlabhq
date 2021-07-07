# frozen_string_literal: true

class ReScheduleLatestPipelineIdPopulation < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 100
  MIGRATION = 'PopulateLatestPipelineIds'

  disable_ddl_transaction!

  def up
    return unless Gitlab.ee?

    queue_background_migration_jobs_by_range_at_intervals(
      Gitlab::BackgroundMigration::PopulateLatestPipelineIds::ProjectSetting.has_vulnerabilities_without_latest_pipeline_set,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      primary_column_name: 'project_id'
    )
  end

  def down
    # no-op
  end
end

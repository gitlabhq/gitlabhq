# frozen_string_literal: true

class ScheduleProductivityAnalyticsBackfill < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 10_000
  INTERVAL = 3.minutes
  MIGRATION = 'Gitlab::BackgroundMigration::RecalculateProductivityAnalytics'.freeze

  disable_ddl_transaction!

  def up
    return unless Gitlab.ee?

    metrics_model = Class.new(ActiveRecord::Base) do
      self.table_name = 'merge_request_metrics'

      include ::EachBatch
    end

    scope = metrics_model.where("merged_at >= ?", 3.months.ago)

    queue_background_migration_jobs_by_range_at_intervals(scope, MIGRATION, INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end

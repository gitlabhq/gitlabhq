# frozen_string_literal: true

class AddMetricsToBatchedBackgroundMigrationJobs < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :batched_background_migration_jobs, :metrics, :jsonb, null: false, default: {}
  end
end

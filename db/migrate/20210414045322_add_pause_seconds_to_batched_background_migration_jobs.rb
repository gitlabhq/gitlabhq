# frozen_string_literal: true

class AddPauseSecondsToBatchedBackgroundMigrationJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :batched_background_migration_jobs, :pause_ms, :integer, null: false, default: 100
  end
end

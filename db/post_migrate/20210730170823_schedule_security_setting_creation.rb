# frozen_string_literal: true

class ScheduleSecuritySettingCreation < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'CreateSecuritySetting'
  BATCH_SIZE = 1000
  INTERVAL = 5.minutes.to_i

  disable_ddl_transaction!

  def up
    return unless Gitlab.ee? # Security Settings available only in EE version

    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('projects'),
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  # We're adding data so no need for rollback
  def down
  end
end

# frozen_string_literal: true

class ScheduleDisableExpirationPoliciesLinkedToNoContainerImages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 30_000
  DELAY = 2.minutes.freeze
  DOWNTIME = false
  MIGRATION = 'DisableExpirationPoliciesLinkedToNoContainerImages'

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('container_expiration_policies').where(enabled: true),
      MIGRATION,
      DELAY,
      batch_size: BATCH_SIZE,
      track_jobs: false,
      primary_column_name: :project_id
    )
  end

  def down
    # this migration is irreversible

    # we can't accuretaly know which policies were previously enabled during the background migration
  end
end

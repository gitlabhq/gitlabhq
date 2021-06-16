# frozen_string_literal: true

class RetryBackfillTraversalIds < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  ROOTS_MIGRATION = 'BackfillNamespaceTraversalIdsRoots'
  CHILDREN_MIGRATION = 'BackfillNamespaceTraversalIdsChildren'
  DOWNTIME = false
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    duration = requeue_background_migration_jobs_by_range_at_intervals(ROOTS_MIGRATION, DELAY_INTERVAL)
    requeue_background_migration_jobs_by_range_at_intervals(CHILDREN_MIGRATION, DELAY_INTERVAL, initial_delay: duration)
  end

  def down
    # no-op
  end
end

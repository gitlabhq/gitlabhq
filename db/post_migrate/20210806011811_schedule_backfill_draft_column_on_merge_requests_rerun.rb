# frozen_string_literal: true

class ScheduleBackfillDraftColumnOnMergeRequestsRerun < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'BackfillDraftStatusOnMergeRequests'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50

  disable_ddl_transaction!

  def up
    eligible_mrs = Gitlab::BackgroundMigration::BackfillDraftStatusOnMergeRequests::MergeRequest.eligible

    queue_background_migration_jobs_by_range_at_intervals(
      eligible_mrs,
      MIGRATION,
      DELAY_INTERVAL,
      track_jobs: true,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # noop
    #
  end
end

# frozen_string_literal: true

class DropInvalidRemediations < Gitlab::Database::Migration[1.0]
  BATCH_SIZE = 3_000
  DELAY_INTERVAL = 3.minutes
  MIGRATION_NAME = 'DropInvalidRemediations'
  DAY_PRIOR_TO_BUG_INTRODUCTION = DateTime.new(2021, 8, 1, 0, 0, 0)

  disable_ddl_transaction!

  def up
    return unless Gitlab.ee?

    relation = Gitlab::BackgroundMigration::DropInvalidRemediations::FindingRemediation.where("created_at > ?", DAY_PRIOR_TO_BUG_INTRODUCTION)
    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          MIGRATION_NAME,
                                                          DELAY_INTERVAL,
                                                          batch_size: BATCH_SIZE,
                                                          track_jobs: true)
  end

  def down
    # no-op
  end
end

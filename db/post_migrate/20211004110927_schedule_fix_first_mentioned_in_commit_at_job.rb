# frozen_string_literal: true

class ScheduleFixFirstMentionedInCommitAtJob < Gitlab::Database::Migration[1.0]
  MIGRATION = 'FixFirstMentionedInCommitAt'
  BATCH_SIZE = 10_000
  INTERVAL = 2.minutes.to_i

  disable_ddl_transaction!

  def up
    scope = Gitlab::BackgroundMigration::FixFirstMentionedInCommitAt::TmpIssueMetrics
      .from_2020

    queue_background_migration_jobs_by_range_at_intervals(
      scope,
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true,
      primary_column_name: :issue_id
    )
  end

  def down
    # noop
  end
end

# frozen_string_literal: true

class BackfillIssuesUpvotesCount < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  MIGRATION = 'BackfillUpvotesCountOnIssues'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5_000

  def up
    scope = Issue.joins("INNER JOIN award_emoji e ON e.awardable_id = issues.id AND e.awardable_type = 'Issue' AND e.name = 'thumbsup'")

    queue_background_migration_jobs_by_range_at_intervals(
      scope,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end

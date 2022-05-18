# frozen_string_literal: true

class SchedulePopulateRequirementsIssueId < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # 2022-05-06 There are no requirements with nil issue_id on .com
  # this migration is supposed to fix records that could have nil issue_id
  # on self managed instances.
  BATCH_SIZE = 100

  MIGRATION = 'MigrateRequirementsToWorkItems'

  disable_ddl_transaction!

  class Requirement < MigrationRecord
    include EachBatch

    self.table_name = 'requirements'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Requirement.where(issue_id: nil),
      MIGRATION,
      2.minutes,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # NO OP
  end
end

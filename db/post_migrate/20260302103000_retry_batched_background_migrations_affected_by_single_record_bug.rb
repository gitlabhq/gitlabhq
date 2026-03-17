# frozen_string_literal: true

class RetryBatchedBackgroundMigrationsAffectedBySingleRecordBug < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_shared
  milestone '18.10'

  # The bug (fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224446) caused
  # batched background migrations to be marked as finished without executing when the target
  # table had a single record (min_value == max_value or min_cursor == max_cursor).
  #
  # The version range is derived from the `queued_migration_version` field in
  # db/docs/batched_background_migrations/*.yml for milestones 18.5 through 18.9.
  #
  # - EARLIEST: first BBM queued in 18.5 (backfill_workspace_agentk_states)
  # - LATEST: last post-deploy migration shipped with 18.9
  #
  # 18.5 is the lower bound because it is a required upgrade stop, so any BBM from
  # before 18.5 would have been enqueued with non-buggy code.
  # 18.9 is included because instances running 18.9 before the backport patch was
  # released could also be affected.
  #
  # We additionally filter on migrations that have no jobs, since the bug caused
  # migrations to be marked as finished without ever creating any jobs.
  # This avoids resetting legitimate single-record migrations from older milestones
  # whose queued_migration_version overlaps our range.
  #
  # This resets affected BBMs to paused so the scheduler picks them up and re-executes them.
  EARLIEST_AFFECTED_VERSION = '20250905091200'
  LATEST_AFFECTED_VERSION = '20260216140430'

  def up
    execute(<<~SQL)
      WITH affected_migrations AS (
        SELECT m.id
        FROM batched_background_migrations m
        LEFT JOIN batched_background_migration_jobs j ON m.id = j.batched_background_migration_id
        WHERE j.id IS NULL
          AND m.status IN (3, 6)
          AND m.queued_migration_version BETWEEN '#{EARLIEST_AFFECTED_VERSION}' AND '#{LATEST_AFFECTED_VERSION}'
          AND (
            (m.min_value IS NOT NULL AND m.min_value = m.max_value)
            OR
            (m.min_cursor IS NOT NULL AND m.min_cursor = m.max_cursor)
          )
      )
      UPDATE batched_background_migrations
      SET status = 0, finished_at = NULL
      FROM affected_migrations
      WHERE batched_background_migrations.id = affected_migrations.id
    SQL
  end

  def down; end
end

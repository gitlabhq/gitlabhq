# frozen_string_literal: true

class ExecuteBatchedBackgroundMigrationsAffectedBySingleRecordBugBackport1 < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_shared
  milestone '18.9'

  disable_ddl_transaction!

  # Backport of https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227592
  # with the following changes:
  #   - status filter changed to `.where(status: [FINISHED, FINALIZED])`
  #   - migration version changed to `20251205040000` (before the first post-deployment migration in 18.9)
  #   - milestone changed to 18.9

  EARLIEST_AFFECTED_VERSION = '20250905091200'
  LATEST_AFFECTED_VERSION = '20260216140430'

  PAUSED = 0
  ACTIVE = 1
  FINISHED = 3
  FINALIZED = 6

  def up
    migrations_sql = Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(gitlab_schema: Gitlab::Database.gitlab_schemas_for_connection(connection))
      .where(queued_migration_version: EARLIEST_AFFECTED_VERSION..LATEST_AFFECTED_VERSION)
      .where(status: [FINISHED, FINALIZED])
      .to_sql

    sql = <<~SQL
        WITH migrations AS (#{migrations_sql})
        SELECT m.*
        FROM migrations m
        LEFT JOIN batched_background_migration_jobs j ON m.id = j.batched_background_migration_id
        WHERE j.id IS NULL
          AND (
            (m.min_value IS NOT NULL AND m.min_value = m.max_value)
            OR
            (m.min_cursor IS NOT NULL AND m.min_cursor = m.max_cursor)
          )
    SQL

    migrations = Gitlab::Database::BackgroundMigration::BatchedMigration.find_by_sql(sql)

    migrations.each do |m|
      # Skip execution if the job class is missing
      next unless Gitlab::BackgroundMigration.const_defined?(m.job_class_name)

      m.update_columns(status: ACTIVE)

      send(
        :ensure_batched_background_migration_is_finished,
        job_class_name: m.job_class_name,
        table_name: m.table_name,
        column_name: m.column_name,
        job_arguments: m.job_arguments,
        finalize: true,
        skip_early_finalization_validation: true
      )
    end
  end

  def down; end
end

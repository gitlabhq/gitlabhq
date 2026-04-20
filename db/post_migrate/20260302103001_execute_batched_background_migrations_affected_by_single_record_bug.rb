# frozen_string_literal: true

class ExecuteBatchedBackgroundMigrationsAffectedBySingleRecordBug < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_shared
  milestone '18.10'

  disable_ddl_transaction!

  # A bug (fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224446) caused
  # batched background migrations to be marked as finished without executing when the target
  # table had a single record (min_value == max_value or min_cursor == max_cursor). While this
  # bug was fixed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224446 we still
  # have to execute the migrations that were already affected. The first attempt to do this was
  # in 20260302103000, but it incorrectly sets migration's status as 'paused' instead of 'active'
  # and also will not work when Sidekiw is stopped (i.e. when upgrading with downtime).
  #
  # This migrartion fetches all migrations marked as paused with 20260302103000
  # and executes them.
  #
  # The version range and all other filters are the same as the one used in 20260302103000.
  EARLIEST_AFFECTED_VERSION = '20250905091200'
  LATEST_AFFECTED_VERSION = '20260216140430'

  PAUSED = 0
  ACTIVE = 1
  FINALIZED = 6

  FINALIZE_JOBS = %w[
    BackfillAwardEmojiShardingKey
    BackfillMissingNamespaceIdOnNotes
    BackfillShardingKeyAndCleanLabelLinksTable
    BackfillSlackIntegrationsScopesShardingKey
  ].freeze

  def up
    migrations_sql = Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(gitlab_schema: Gitlab::Database.gitlab_schemas_for_connection(connection))
      .where(queued_migration_version: EARLIEST_AFFECTED_VERSION..LATEST_AFFECTED_VERSION)
      .where(status: PAUSED) # migrations paused with 20260302103000
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
      # Mark as finalized jobs that reference tables which have been dropped in a later migration
      if FINALIZE_JOBS.include?(m.job_class_name)
        m.update!(status: FINALIZED, finished_at: Time.current)
        next
      end
      # Skip execution if the job class is missing
      next unless Gitlab::BackgroundMigration.const_defined?(m.job_class_name)

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

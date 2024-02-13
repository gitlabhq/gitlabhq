# frozen_string_literal: true

class EnsureBackfillForCiBuildsIntegerColumnsIsFinished < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  milestone '16.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  TABLE_NAME = :ci_builds
  COLUMN_NAMES = %w[
    auto_canceled_by_id
    commit_id
    erased_by_id
    project_id
    runner_id
    trigger_request_id
    upstream_pipeline_id
    user_id
  ]
  BIGINT_COLUMN_NAMES = COLUMN_NAMES.map { |name| "#{name}_convert_to_bigint" }

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [COLUMN_NAMES, BIGINT_COLUMN_NAMES]
    )
  end

  def down
    # no-op
  end
end

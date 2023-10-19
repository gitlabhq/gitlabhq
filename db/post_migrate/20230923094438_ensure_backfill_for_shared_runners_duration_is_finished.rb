# frozen_string_literal: true

class EnsureBackfillForSharedRunnersDurationIsFinished < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  TABLE_NAMES = %i[ci_project_monthly_usages ci_namespace_monthly_usages]

  def up
    TABLE_NAMES.each do |table_name|
      ensure_batched_background_migration_is_finished(
        job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
        table_name: table_name,
        column_name: 'id',
        job_arguments: [
          %w[shared_runners_duration],
          %w[shared_runners_duration_convert_to_bigint]
        ]
      )
    end
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class EnsureMergeRequestMetricsIdBigintBackfillIsFinishedForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless should_run?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: 'merge_request_metrics',
      column_name: 'id',
      job_arguments: [['id'], ['id_convert_to_bigint']]
    )
  end

  def down
    # no-op
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end

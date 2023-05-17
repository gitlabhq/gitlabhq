# frozen_string_literal: true

class EnsureMergeRequestMetricsIdBigintBackfillIsFinishedForSelfHosts < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE_NAME = 'merge_request_metrics'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [['id'], ['id_convert_to_bigint']]
    )
  end

  def down
    # no-op
  end
end

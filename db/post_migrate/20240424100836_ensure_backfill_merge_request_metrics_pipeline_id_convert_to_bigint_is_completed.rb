# frozen_string_literal: true

class EnsureBackfillMergeRequestMetricsPipelineIdConvertToBigintIsCompleted < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.0'

  TABLE_NAME = :merge_request_metrics

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [['pipeline_id'], ['pipeline_id_convert_to_bigint']]
    )
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class EnsureBackfillMergeRequestsHeadPipelineIdIsCompleted < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.1'

  TABLE_NAME = :merge_requests

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [['head_pipeline_id'], ['head_pipeline_id_convert_to_bigint']]
    )
  end

  def down
    # no-op
  end
end

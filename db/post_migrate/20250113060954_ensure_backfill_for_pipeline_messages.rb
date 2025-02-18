# frozen_string_literal: true

class EnsureBackfillForPipelineMessages < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiPipelineMessagesProjectId"
  TABLE = :ci_pipeline_messages
  PRIMARY_KEY = :id
  ARGUMENTS = %i[
    project_id
    p_ci_pipelines
    project_id
    pipeline_id
    partition_id
  ]

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: TABLE,
      column_name: PRIMARY_KEY,
      job_arguments: ARGUMENTS,
      finalize: true
    )
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class FinalizeBackfillPartitionIdCiPipelineMetadata < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  MIGRATION = 'BackfillPartitionIdCiPipelineMetadata'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :ci_pipeline_metadata,
      column_name: :pipeline_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class FinalizeBackfillPipelineProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillOrDropCiPipelineOnProjectId'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :ci_pipelines,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

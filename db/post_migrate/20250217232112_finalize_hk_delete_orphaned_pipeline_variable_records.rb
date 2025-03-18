# frozen_string_literal: true

class FinalizeHkDeleteOrphanedPipelineVariableRecords < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'DeleteOrphanedPipelineVariableRecords',
      table_name: :p_ci_pipeline_variables,
      column_name: :pipeline_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end

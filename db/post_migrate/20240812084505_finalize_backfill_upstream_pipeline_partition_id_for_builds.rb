# frozen_string_literal: true

class FinalizeBackfillUpstreamPipelinePartitionIdForBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillUpstreamPipelinePartitionIdOnPCiBuilds'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :p_ci_builds,
      column_name: :upstream_pipeline_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

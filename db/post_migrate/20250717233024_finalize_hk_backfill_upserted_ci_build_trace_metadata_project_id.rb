# frozen_string_literal: true

class FinalizeHkBackfillUpsertedCiBuildTraceMetadataProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillUpsertedCiBuildTraceMetadataProjectId',
      table_name: :p_ci_build_trace_metadata,
      column_name: :build_id,
      job_arguments: [:project_id, :p_ci_builds, :project_id, :build_id, :partition_id],
      finalize: true
    )
  end

  def down; end
end

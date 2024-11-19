# frozen_string_literal: true

class FinalizeBackfillOperationsFeatureFlagsIssuesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillOperationsFeatureFlagsIssuesProjectId',
      table_name: :operations_feature_flags_issues,
      column_name: :id,
      job_arguments: [:project_id, :operations_feature_flags, :project_id, :feature_flag_id],
      finalize: true
    )
  end

  def down; end
end

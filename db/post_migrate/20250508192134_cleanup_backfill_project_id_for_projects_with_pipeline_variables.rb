# frozen_string_literal: true

class CleanupBackfillProjectIdForProjectsWithPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillProjectIdForProjectsWithPipelineVariables"

  def up
    delete_batched_background_migration(MIGRATION, :p_ci_pipeline_variables, :project_id, [])
  end

  def down
    # no-op
  end
end

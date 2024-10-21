# frozen_string_literal: true

class FinalizeBackfillCiJobVariablesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillCiJobVariablesProjectId'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :ci_job_variables,
      column_name: :id,
      job_arguments: [
        :project_id,
        :p_ci_builds,
        :project_id,
        :job_id
      ],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

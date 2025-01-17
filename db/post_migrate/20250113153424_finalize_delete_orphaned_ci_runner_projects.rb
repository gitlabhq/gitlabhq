# frozen_string_literal: true

class FinalizeDeleteOrphanedCiRunnerProjects < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'DeleteOrphanedCiRunnerProjects',
      table_name: :ci_runner_projects,
      column_name: :runner_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end

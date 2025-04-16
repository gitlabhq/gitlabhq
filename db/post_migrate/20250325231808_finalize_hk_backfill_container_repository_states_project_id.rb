# frozen_string_literal: true

class FinalizeHkBackfillContainerRepositoryStatesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillContainerRepositoryStatesProjectId',
      table_name: :container_repository_states,
      column_name: :container_repository_id,
      job_arguments: [:project_id, :container_repositories, :project_id, :container_repository_id],
      finalize: true
    )
  end

  def down; end
end

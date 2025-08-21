# frozen_string_literal: true

class FinalizeBackfillDesignManagementRepositoryStatesNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDesignManagementRepositoryStatesNamespaceId',
      table_name: :design_management_repository_states,
      column_name: :design_management_repository_id,
      job_arguments: [:namespace_id, :design_management_repositories, :namespace_id, :design_management_repository_id],
      finalize: true
    )
  end

  def down; end
end

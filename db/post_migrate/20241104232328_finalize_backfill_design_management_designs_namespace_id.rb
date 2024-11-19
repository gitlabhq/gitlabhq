# frozen_string_literal: true

class FinalizeBackfillDesignManagementDesignsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDesignManagementDesignsNamespaceId',
      table_name: :design_management_designs,
      column_name: :id,
      job_arguments: [:namespace_id, :projects, :namespace_id, :project_id],
      finalize: true
    )
  end

  def down; end
end

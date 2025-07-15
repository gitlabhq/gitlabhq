# frozen_string_literal: true

class FinalizeBackfillPackagesDebianProjectComponentFilesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesDebianProjectComponentFilesProjectId',
      table_name: :packages_debian_project_component_files,
      column_name: :id,
      job_arguments: [:project_id, :packages_debian_project_components, :project_id, :component_id],
      finalize: true
    )
  end

  def down; end
end

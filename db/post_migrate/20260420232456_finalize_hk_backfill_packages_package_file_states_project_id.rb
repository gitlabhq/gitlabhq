# frozen_string_literal: true

class FinalizeHkBackfillPackagesPackageFileStatesProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesPackageFileStatesProjectId',
      table_name: :packages_package_file_states,
      column_name: :id,
      job_arguments: [:project_id, :packages_package_files, :project_id, :package_file_id],
      finalize: true
    )
  end

  def down; end
end

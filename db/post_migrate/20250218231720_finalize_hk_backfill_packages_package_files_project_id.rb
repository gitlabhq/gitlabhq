# frozen_string_literal: true

class FinalizeHkBackfillPackagesPackageFilesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesPackageFilesProjectId',
      table_name: :packages_package_files,
      column_name: :id,
      job_arguments: [:project_id, :packages_packages, :project_id, :package_id],
      finalize: true
    )
  end

  def down; end
end

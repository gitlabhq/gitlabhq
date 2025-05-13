# frozen_string_literal: true

class FinalizeHkBackfillPackagesRpmMetadataProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesRpmMetadataProjectId',
      table_name: :packages_rpm_metadata,
      column_name: :package_id,
      job_arguments: [:project_id, :packages_packages, :project_id, :package_id],
      finalize: true
    )
  end

  def down; end
end

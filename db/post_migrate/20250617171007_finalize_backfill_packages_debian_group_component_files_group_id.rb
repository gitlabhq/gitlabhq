# frozen_string_literal: true

class FinalizeBackfillPackagesDebianGroupComponentFilesGroupId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesDebianGroupComponentFilesGroupId',
      table_name: :packages_debian_group_component_files,
      column_name: :id,
      job_arguments: [:group_id, :packages_debian_group_components, :group_id, :component_id],
      finalize: true
    )
  end

  def down; end
end

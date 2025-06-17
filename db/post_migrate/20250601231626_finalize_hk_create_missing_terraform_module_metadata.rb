# frozen_string_literal: true

class FinalizeHkCreateMissingTerraformModuleMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CreateMissingTerraformModuleMetadata',
      table_name: :packages_packages,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end

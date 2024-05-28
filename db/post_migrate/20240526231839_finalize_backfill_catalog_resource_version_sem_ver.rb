# frozen_string_literal: true

class FinalizeBackfillCatalogResourceVersionSemVer < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillCatalogResourceVersionSemVer',
      table_name: :catalog_resource_versions,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end

# frozen_string_literal: true

class FinalizeBackfillCatalogResourceVersionsReleasedAt < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  MIGRATION = 'BackfillCatalogResourceVersionsReleasedAt'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :catalog_resource_versions,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class FinalizeOsSbomComponentNormalizationMigration < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.4'

  MIGRATION_NAME = 'RemoveNamespaceFromOsTypeSbomComponents'

  disable_ddl_transaction!

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION_NAME,
      table_name: :sbom_components,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class FinalizeDeleteStalePackagesNpmMetadataCaches < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.6'

  MIGRATION = 'DeleteStalePackagesNpmMetadataCaches'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :packages_npm_metadata_caches,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

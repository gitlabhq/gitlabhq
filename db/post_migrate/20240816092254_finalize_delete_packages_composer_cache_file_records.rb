# frozen_string_literal: true

class FinalizeDeletePackagesComposerCacheFileRecords < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  MIGRATION = 'DeletePackagesComposerCacheFileRecords'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :packages_composer_cache_files,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

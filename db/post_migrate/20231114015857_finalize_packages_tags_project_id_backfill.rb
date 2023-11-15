# frozen_string_literal: true

class FinalizePackagesTagsProjectIdBackfill < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.7'

  MIGRATION = 'BackfillPackagesTagsProjectId'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :packages_tags,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

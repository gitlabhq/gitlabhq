# frozen_string_literal: true

class FinalizeDeleteOrphanedBuildRecords < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'DeleteOrphanedBuildRecords'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :p_ci_builds,
      column_name: :commit_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end

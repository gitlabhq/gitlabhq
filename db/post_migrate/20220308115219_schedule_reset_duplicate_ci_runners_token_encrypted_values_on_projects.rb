# frozen_string_literal: true

class ScheduleResetDuplicateCiRunnersTokenEncryptedValuesOnProjects < Gitlab::Database::Migration[1.0]
  MIGRATION = 'ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects'
  TOKEN_COLUMN_NAME = :runners_token_encrypted
  TEMP_INDEX_NAME = "tmp_index_projects_on_id_and_#{TOKEN_COLUMN_NAME}"
  BATCH_SIZE = 10_000
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:id, TOKEN_COLUMN_NAME], where: "#{TOKEN_COLUMN_NAME} IS NOT NULL", unique: false, name: TEMP_INDEX_NAME

    queue_background_migration_jobs_by_range_at_intervals(
      Gitlab::BackgroundMigration::ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects::Project.base_query,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    remove_concurrent_index_by_name(:projects, name: TEMP_INDEX_NAME)
  end
end

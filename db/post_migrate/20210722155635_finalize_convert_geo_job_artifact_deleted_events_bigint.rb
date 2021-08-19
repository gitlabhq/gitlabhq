# frozen_string_literal: true

class FinalizeConvertGeoJobArtifactDeletedEventsBigint < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'geo_job_artifact_deleted_events'
  COLUMN_NAME = 'job_artifact_id'
  COLUMN_NAME_CONVERTED = "#{COLUMN_NAME}_convert_to_bigint"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [[COLUMN_NAME], [COLUMN_NAME_CONVERTED]]
    )

    swap
  end

  def down
    swap
  end

  def swap
    old_index_name = 'index_geo_job_artifact_deleted_events_on_job_artifact_id'

    bigint_index_name = 'index_geo_job_artifact_deleted_events_on_job_artifact_id_bigint'
    add_concurrent_index TABLE_NAME, COLUMN_NAME_CONVERTED, name: bigint_index_name

    with_lock_retries(raise_on_exhaustion: true) do
      execute("LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE")

      temp_name = quote_column_name("#{COLUMN_NAME}_tmp")
      old_column_name = quote_column_name(COLUMN_NAME)
      new_column_name = quote_column_name(COLUMN_NAME_CONVERTED)

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{old_column_name} TO #{temp_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{new_column_name} TO #{old_column_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{new_column_name}"

      change_column_default TABLE_NAME, COLUMN_NAME, nil
      change_column_default TABLE_NAME, COLUMN_NAME_CONVERTED, 0

      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME).name(COLUMN_NAME, COLUMN_NAME_CONVERTED)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      execute "DROP INDEX #{old_index_name}"

      rename_index TABLE_NAME, bigint_index_name, old_index_name
    end
  end
end

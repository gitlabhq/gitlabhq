# frozen_string_literal: true

class SwapBigintGeoEventId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '16.9'

  disable_ddl_transaction!

  TABLE_NAME = 'geo_event_log'
  COLUMN_NAME = 'geo_event_id'
  INDEX_NAME = 'index_geo_event_log_on_geo_event_id'
  BIGINT_COLUMN_NAME = 'geo_event_id_convert_to_bigint'

  # For the FK from 'geo_event_log' table referencing 'geo_events'
  FK_SOURCE_TABLE_NAME = 'geo_events'
  FK_NAME = 'fk_geo_event_log_on_geo_event_id'
  TEMP_FK_NAME = 'fk_geo_event_id_convert_to_bigint'

  def up
    swap
  end

  def down
    swap
  end

  def swap
    add_bigint_column_indexes TABLE_NAME, COLUMN_NAME

    unless foreign_key_exists?(TABLE_NAME, name: TEMP_FK_NAME)
      add_concurrent_foreign_key TABLE_NAME, FK_SOURCE_TABLE_NAME,
        name: TEMP_FK_NAME,
        on_delete: :cascade,
        column: BIGINT_COLUMN_NAME
    end

    with_lock_retries(raise_on_exhaustion: true) do
      # Lock the table to avoid deadlocks
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # Swap the column names
      temp_name = quote_column_name('id_tmp')
      id_name = quote_column_name(COLUMN_NAME)
      id_convert_to_bigint_name = quote_column_name(BIGINT_COLUMN_NAME)
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_name} TO #{temp_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_convert_to_bigint_name} TO #{id_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{id_convert_to_bigint_name}"

      # Reset the trigger function
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(
        TABLE_NAME, connection: connection).name(
          COLUMN_NAME,
          BIGINT_COLUMN_NAME
        )
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"
    end

    # Rename the temporary FK
    execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT #{FK_NAME} CASCADE"
    rename_constraint TABLE_NAME, TEMP_FK_NAME, FK_NAME

    # Rename index
    execute "DROP INDEX CONCURRENTLY #{INDEX_NAME}"
    rename_index TABLE_NAME, bigint_index_name(INDEX_NAME), INDEX_NAME
  end
end

# frozen_string_literal: true

class SwapColumnsForSystemNoteMetadataId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  milestone '16.9'

  TABLE_NAME = 'system_note_metadata'
  PRIMARY_KEY_CONSTRAINT_NAME = 'system_note_metadata_pkey'
  PRIMARY_KEY_INDEX_NAME = 'index_system_note_metadata_pkey'
  NEW_PRIMARY_KEY_INDEX_NAME = 'index_system_note_metadata_pkey_on_id_convert_to_bigint'

  # For the FK from 'resource_link_events' table referencing 'system_note_metadata'.
  FK_SOURCE_TABLE_NAME = :resource_link_events
  FK_COLUMN_NAME = :system_note_metadata_id
  FK_NAME = 'fk_2a039c40f4'
  TEMP_FK_NAME = 'fk_system_note_metadata_id_convert_to_bigint'

  def up
    swap
  end

  def down
    swap

    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: NEW_PRIMARY_KEY_INDEX_NAME

    add_concurrent_foreign_key FK_SOURCE_TABLE_NAME, TABLE_NAME,
      name: TEMP_FK_NAME,
      column: FK_COLUMN_NAME,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      validate: false
  end

  def swap
    # This will replace the existing system_note_metadata_pkey index for the primary key
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: NEW_PRIMARY_KEY_INDEX_NAME

    # This will replace the existing fk_2a039c40f4
    add_concurrent_foreign_key FK_SOURCE_TABLE_NAME, TABLE_NAME,
      name: TEMP_FK_NAME,
      column: FK_COLUMN_NAME,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME}, #{FK_SOURCE_TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # Swap columns
      temp_column_name = quote_column_name(:id_tmp)
      id_column_name = quote_column_name(:id)
      id_convert_to_bigint_name = quote_column_name(:id_convert_to_bigint)
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_column_name} TO #{temp_column_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_convert_to_bigint_name} TO #{id_column_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_column_name} TO #{id_convert_to_bigint_name}"

      # Reset trigger
      function_name = Gitlab::Database::UnidirectionalCopyTrigger
        .on_table(TABLE_NAME, connection: connection)
        .name(:id, :id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      seq_name = "system_note_metadata_id_seq"
      execute "ALTER SEQUENCE #{seq_name} OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('#{seq_name}'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # Swap pkey constraint
      # This will drop fk_2a039c40f4 ("resource_link_events" REFERENCES system_note_metadata(id) ON DELETE CASCADE)
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT #{PRIMARY_KEY_CONSTRAINT_NAME} CASCADE"
      rename_index TABLE_NAME, NEW_PRIMARY_KEY_INDEX_NAME, PRIMARY_KEY_INDEX_NAME
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT #{PRIMARY_KEY_CONSTRAINT_NAME} PRIMARY KEY USING INDEX #{PRIMARY_KEY_INDEX_NAME}"

      # Rename the new FK
      rename_constraint FK_SOURCE_TABLE_NAME, TEMP_FK_NAME, FK_NAME
    end
  end
end

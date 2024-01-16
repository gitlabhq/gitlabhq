# frozen_string_literal: true

class AddUniqueIndexToSystemNoteMetadataOnIdConvertToBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  TABLE_NAME = :system_note_metadata
  INDEX_NAME = 'index_system_note_metadata_pkey_on_id_convert_to_bigint'

  def up
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME
  end
end

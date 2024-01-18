# frozen_string_literal: true

class DropUniqueIndexToSystemNoteMetadataOnIdConvertToBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  TABLE_NAME = :system_note_metadata
  INDEX_NAME = 'index_system_note_metadata_pkey_on_id_convert_to_bigint'

  def up
    return if Gitlab.com?

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    return if Gitlab.com?

    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME
  end
end

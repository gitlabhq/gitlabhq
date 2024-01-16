# frozen_string_literal: true

class CreateIndexOnIdConvertToBigintForSystemNoteMetadataAsync < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  TABLE_NAME = :system_note_metadata
  INDEX_NAME = 'index_system_note_metadata_pkey_on_id_convert_to_bigint'

  def up
    prepare_async_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME
  end
end

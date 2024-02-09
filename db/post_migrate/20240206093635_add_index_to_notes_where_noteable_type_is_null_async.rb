# frozen_string_literal: true

class AddIndexToNotesWhereNoteableTypeIsNullAsync < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  TABLE_NAME = :notes
  INDEX_NAME = 'temp_index_on_notes_with_null_noteable_type'

  def up
    prepare_async_index TABLE_NAME, :id, where: "noteable_type IS NULL", name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, INDEX_NAME
  end
end

# frozen_string_literal: true

class AddIndexToNotesWhereNoteableTypeIsNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  TABLE_NAME = :notes
  INDEX_NAME = 'temp_index_on_notes_with_null_noteable_type'

  def up
    add_concurrent_index TABLE_NAME, :id, name: INDEX_NAME, where: "noteable_type IS NULL"
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

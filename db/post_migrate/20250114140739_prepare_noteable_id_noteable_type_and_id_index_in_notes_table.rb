# frozen_string_literal: true

class PrepareNoteableIdNoteableTypeAndIdIndexInNotesTable < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  INDEX_NAME = 'index_notes_on_noteable_id_noteable_type_and_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- needed to iterate through notes of a single issuable when it has a lot of notes
    prepare_async_index :notes, [:noteable_id, :noteable_type, :id], name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :notes, [:noteable_id, :noteable_type, :id], name: INDEX_NAME
  end
end

# frozen_string_literal: true

class RemoveNotesTrigramIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  NOTES_TRIGRAM_INDEX_NAME = 'index_notes_on_note_trigram'

  def up
    remove_concurrent_index_by_name(:notes, NOTES_TRIGRAM_INDEX_NAME)
  end

  def down
    add_concurrent_index :notes, :note, name: NOTES_TRIGRAM_INDEX_NAME, using: :gin, opclass: { content: :gin_trgm_ops }
  end
end

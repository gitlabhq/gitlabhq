# frozen_string_literal: true

class DropNotesNoteTrigramIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_notes_on_note_gin_trigram'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end

  def down
    # no-op
    # we never want to add this index back since it doesn't exist in production
    # we are only using this migration to cleanup other environments where this index does exist
  end
end

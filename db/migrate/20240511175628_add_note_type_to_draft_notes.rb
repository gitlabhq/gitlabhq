# frozen_string_literal: true

class AddNoteTypeToDraftNotes < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :draft_notes, :note_type, :smallint, null: true
  end
end

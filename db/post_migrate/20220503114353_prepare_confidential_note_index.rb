# frozen_string_literal: true

class PrepareConfidentialNoteIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_notes_on_confidential'

  def up
    prepare_async_index :notes, :confidential, where: 'confidential = true', name: INDEX_NAME
  end

  def down
    unprepare_async_index :notes, :confidential, name: INDEX_NAME
  end
end

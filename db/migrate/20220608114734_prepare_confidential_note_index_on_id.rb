# frozen_string_literal: true

class PrepareConfidentialNoteIndexOnId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_notes_on_id_where_confidential'

  def up
    prepare_async_index :notes, :id, where: 'confidential = true', name: INDEX_NAME
  end

  def down
    unprepare_async_index :notes, :id, name: INDEX_NAME
  end
end

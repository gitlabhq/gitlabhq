# frozen_string_literal: true

class PrepareCreateInternalNotesIndexOnId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_notes_on_id_where_internal'

  def up
    prepare_async_index :notes, :id, where: 'internal = true', name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :notes, INDEX_NAME
  end
end

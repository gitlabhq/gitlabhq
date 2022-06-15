# frozen_string_literal: true

class CreateConfidentialNotesIndexOnId < Gitlab::Database::Migration[2.0]
  OLD_INDEX_NAME = 'index_notes_on_confidential'
  INDEX_NAME = 'index_notes_on_id_where_confidential'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :notes, name: OLD_INDEX_NAME
    add_concurrent_index :notes, :id, where: 'confidential = true', name: INDEX_NAME
  end

  def down
    # we don't have to re-create OLD_INDEX_NAME index
    # because it wasn't used yet, also its creation might be expensive
    remove_concurrent_index_by_name :notes, name: INDEX_NAME
  end
end

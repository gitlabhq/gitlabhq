# frozen_string_literal: true

class CreateConfidentialNotesIndexSynchronously < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_notes_on_confidential'

  disable_ddl_transaction!

  def up
    add_concurrent_index :notes, :confidential, where: 'confidential = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :notes, name: INDEX_NAME
  end
end

# frozen_string_literal: true

class IndexDraftNotesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_draft_notes_on_project_id'

  def up
    add_concurrent_index :draft_notes, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :draft_notes, INDEX_NAME
  end
end

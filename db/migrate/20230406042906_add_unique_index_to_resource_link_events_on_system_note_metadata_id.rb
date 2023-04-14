# frozen_string_literal: true

class AddUniqueIndexToResourceLinkEventsOnSystemNoteMetadataId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'unique_index_on_system_note_metadata_id'

  def up
    add_concurrent_index :resource_link_events, :system_note_metadata_id, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :resource_link_events, name: INDEX_NAME
  end
end

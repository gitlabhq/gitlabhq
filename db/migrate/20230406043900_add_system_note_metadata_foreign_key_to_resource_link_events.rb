# frozen_string_literal: true

class AddSystemNoteMetadataForeignKeyToResourceLinkEvents < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :resource_link_events, :system_note_metadata,
      column: :system_note_metadata_id, on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :resource_link_events, column: :system_note_metadata_id
    end
  end
end

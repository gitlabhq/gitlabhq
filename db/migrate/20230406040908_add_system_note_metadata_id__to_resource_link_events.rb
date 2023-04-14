# frozen_string_literal: true

class AddSystemNoteMetadataIdToResourceLinkEvents < Gitlab::Database::Migration[2.1]
  def change
    add_column :resource_link_events, :system_note_metadata_id, :bigint
  end
end

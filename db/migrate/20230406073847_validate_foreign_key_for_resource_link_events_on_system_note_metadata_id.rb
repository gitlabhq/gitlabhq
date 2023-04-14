# frozen_string_literal: true

class ValidateForeignKeyForResourceLinkEventsOnSystemNoteMetadataId < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :resource_link_events, :system_note_metadata_id
  end

  def down
    # No-op
  end
end

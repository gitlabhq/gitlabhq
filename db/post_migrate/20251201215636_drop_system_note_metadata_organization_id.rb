# frozen_string_literal: true

class DropSystemNoteMetadataOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    remove_column :system_note_metadata, :organization_id
  end

  def down
    add_column :system_note_metadata, :organization_id, :bigint
  end
end

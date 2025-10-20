# frozen_string_literal: true

class DropSystemNoteMetadataOrganizationIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_system_note_metadata_on_organization_id'

  disable_ddl_transaction!
  milestone '18.6'

  def up
    remove_concurrent_index_by_name :system_note_metadata, INDEX_NAME
  end

  def down
    add_concurrent_index :system_note_metadata, :organization_id, name: INDEX_NAME
  end
end

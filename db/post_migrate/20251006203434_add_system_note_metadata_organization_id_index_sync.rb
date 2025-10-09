# frozen_string_literal: true

class AddSystemNoteMetadataOrganizationIdIndexSync < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_system_note_metadata_on_organization_id'

  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_index :system_note_metadata, :organization_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Sharding key colums are an exception
  end

  def down
    remove_concurrent_index_by_name :system_note_metadata, INDEX_NAME
  end
end

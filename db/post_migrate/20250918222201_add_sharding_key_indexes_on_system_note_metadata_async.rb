# frozen_string_literal: true

class AddShardingKeyIndexesOnSystemNoteMetadataAsync < Gitlab::Database::Migration[2.3]
  NAMESPACE_INDEX = 'index_system_note_metadata_on_namespace_id'
  ORGANIZATION_INDEX = 'index_system_note_metadata_on_organization_id'

  milestone '18.5'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Sharding key is an exception
    prepare_async_index :system_note_metadata, :namespace_id, name: NAMESPACE_INDEX
    prepare_async_index :system_note_metadata, :organization_id, name: ORGANIZATION_INDEX
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :system_note_metadata, :namespace_id, name: NAMESPACE_INDEX
    unprepare_async_index :system_note_metadata, :organization_id, name: ORGANIZATION_INDEX
  end
end

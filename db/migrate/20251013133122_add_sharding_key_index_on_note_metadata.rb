# frozen_string_literal: true

class AddShardingKeyIndexOnNoteMetadata < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_note_metadata_on_namespace_id'

  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_concurrent_index :note_metadata, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :note_metadata, INDEX_NAME
  end
end

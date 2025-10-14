# frozen_string_literal: true

class AddSystemNoteMetadataNamespaceIdIndexSync < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_system_note_metadata_on_namespace_id'

  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_concurrent_index :system_note_metadata, :namespace_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Sharding key colums are an exception
  end

  def down
    remove_concurrent_index_by_name :system_note_metadata, INDEX_NAME
  end
end

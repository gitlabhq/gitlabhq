# frozen_string_literal: true

class AddNoteDiffFilesNamespaceIdIndexSync < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_note_diff_files_on_namespace_id'

  disable_ddl_transaction!
  milestone '18.6'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Sharding key columns are an exception
    add_concurrent_index :note_diff_files, :namespace_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :note_diff_files, INDEX_NAME
  end
end

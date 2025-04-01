# frozen_string_literal: true

class AddZoektRepositoriesIndexOnSizeBytes < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = 'idx_zoekt_repositories_on_zoekt_index_id_and_size_bytes'
  TABLE_NAME = 'zoekt_repositories'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- large tables
    add_concurrent_index TABLE_NAME, [:zoekt_index_id, :size_bytes], name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

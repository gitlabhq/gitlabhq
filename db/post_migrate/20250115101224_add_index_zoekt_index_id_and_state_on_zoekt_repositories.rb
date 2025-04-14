# frozen_string_literal: true

class AddIndexZoektIndexIdAndStateOnZoektRepositories < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = :idx_zoekt_repositories_on_zoekt_index_id_and_state
  TABLE_NAME = :zoekt_repositories

  def up
    # rubocop:disable Migration/PreventIndexCreation -- large tables
    add_concurrent_index(TABLE_NAME, %i[zoekt_index_id state], name: INDEX_NAME)
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end

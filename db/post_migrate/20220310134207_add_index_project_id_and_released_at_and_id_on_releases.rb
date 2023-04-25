# frozen_string_literal: true

class AddIndexProjectIdAndReleasedAtAndIdOnReleases < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_releases_on_project_id_and_released_at_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :releases, [:project_id, :released_at, :id],
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :releases, INDEX_NAME
  end
end

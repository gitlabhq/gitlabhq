# frozen_string_literal: true

class IndexReleasesOnProjectIdAndUpdatedAtAndReleasedAt < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  INDEX_NAME = 'index_releases_on_project_id_and_updated_at_and_released_at'

  def up
    add_concurrent_index :releases, [:project_id, :updated_at, :released_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :releases, INDEX_NAME
  end
end

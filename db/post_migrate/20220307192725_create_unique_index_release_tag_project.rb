# frozen_string_literal: true

class CreateUniqueIndexReleaseTagProject < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_releases_on_project_tag_unique'
  OLD_INDEX_NAME = 'index_releases_on_project_id_and_tag'

  disable_ddl_transaction!

  def up
    add_concurrent_index :releases,
                         %i[project_id tag],
                         unique: true,
                         name: INDEX_NAME
    remove_concurrent_index_by_name :releases, name: OLD_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :releases, name: INDEX_NAME
    add_concurrent_index :releases,
                         %i[project_id tag],
                         name: OLD_INDEX_NAME
  end
end

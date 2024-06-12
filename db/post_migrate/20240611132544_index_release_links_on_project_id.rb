# frozen_string_literal: true

class IndexReleaseLinksOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_release_links_on_project_id'

  def up
    add_concurrent_index :release_links, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :release_links, INDEX_NAME
  end
end

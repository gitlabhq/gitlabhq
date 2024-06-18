# frozen_string_literal: true

class IndexWikiPageSlugsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_wiki_page_slugs_on_project_id'

  def up
    add_concurrent_index :wiki_page_slugs, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :wiki_page_slugs, INDEX_NAME
  end
end

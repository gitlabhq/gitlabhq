# frozen_string_literal: true

class IndexWikiPageSlugsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_wiki_page_slugs_on_namespace_id'

  def up
    add_concurrent_index :wiki_page_slugs, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :wiki_page_slugs, INDEX_NAME
  end
end

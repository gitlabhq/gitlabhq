# frozen_string_literal: true

class AddIndexToWikiPageMetaNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  INDEX_NAME = 'index_wiki_page_meta_on_namespace_id'

  def up
    add_concurrent_index :wiki_page_meta, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :wiki_page_meta, name: INDEX_NAME
  end
end

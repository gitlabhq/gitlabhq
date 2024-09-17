# frozen_string_literal: true

class AddNamespacesForeignKeyToWikiPageMeta < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :wiki_page_meta, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :wiki_page_meta, column: :namespace_id
    end
  end
end

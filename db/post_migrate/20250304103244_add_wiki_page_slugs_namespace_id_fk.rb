# frozen_string_literal: true

class AddWikiPageSlugsNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :wiki_page_slugs,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :wiki_page_slugs, column: :namespace_id, reverse_lock_order: true
    end
  end
end

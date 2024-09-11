# frozen_string_literal: true

class AddNamespaceIdToWikiPageMeta < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :wiki_page_meta, :namespace_id, :bigint
  end
end

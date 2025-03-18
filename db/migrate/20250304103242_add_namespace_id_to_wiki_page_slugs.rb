# frozen_string_literal: true

class AddNamespaceIdToWikiPageSlugs < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :wiki_page_slugs, :namespace_id, :bigint
  end
end

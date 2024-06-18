# frozen_string_literal: true

class AddProjectIdToWikiPageSlugs < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :wiki_page_slugs, :project_id, :bigint
  end
end

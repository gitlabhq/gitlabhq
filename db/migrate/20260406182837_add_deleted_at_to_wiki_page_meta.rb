# frozen_string_literal: true

class AddDeletedAtToWikiPageMeta < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :wiki_page_meta, :deleted_at, :datetime_with_timezone, null: true
  end
end

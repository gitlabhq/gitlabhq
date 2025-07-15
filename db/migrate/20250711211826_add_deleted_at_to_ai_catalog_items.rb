# frozen_string_literal: true

class AddDeletedAtToAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :ai_catalog_items, :deleted_at, :datetime_with_timezone
  end
end

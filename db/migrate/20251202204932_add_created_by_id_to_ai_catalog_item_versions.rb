# frozen_string_literal: true

class AddCreatedByIdToAiCatalogItemVersions < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :ai_catalog_item_versions, :created_by_id, :bigint
  end
end

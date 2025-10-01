# frozen_string_literal: true

class AddVerificationLevelToAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :ai_catalog_items, :verification_level, :integer, limit: 2, default: 0, null: false
  end
end

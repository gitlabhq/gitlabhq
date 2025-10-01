# frozen_string_literal: true

class AddIndexToAiCatalogItemsVerificationLevel < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_catalog_items_on_verification_level'

  def up
    add_concurrent_index :ai_catalog_items, :verification_level, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_items, INDEX_NAME
  end
end

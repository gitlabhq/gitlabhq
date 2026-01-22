# frozen_string_literal: true

class AddUniqueIndexToAiCatalogItemConsumersServiceAccountId < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_catalog_item_consumers_on_service_account_id'
  INDEX_NAME_UNIQUE = 'index_ai_catalog_item_consumers_on_service_account_id_unique'

  def up
    add_concurrent_index :ai_catalog_item_consumers, :service_account_id, unique: true, name: INDEX_NAME_UNIQUE

    remove_concurrent_index :ai_catalog_item_consumers, :service_account_id, name: INDEX_NAME
  end

  def down
    add_concurrent_index :ai_catalog_item_consumers, :service_account_id, name: INDEX_NAME

    remove_concurrent_index :ai_catalog_item_consumers, :service_account_id, name: INDEX_NAME_UNIQUE
  end
end

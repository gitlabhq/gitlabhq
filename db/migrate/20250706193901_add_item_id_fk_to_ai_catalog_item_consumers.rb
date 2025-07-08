# frozen_string_literal: true

class AddItemIdFkToAiCatalogItemConsumers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_concurrent_foreign_key :ai_catalog_item_consumers, :ai_catalog_items, column: :ai_catalog_item_id,
      on_delete: :restrict
  end

  def down
    with_lock_retries do
      remove_foreign_key :ai_catalog_item_consumers, column: :ai_catalog_item_id
    end
  end
end

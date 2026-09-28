# frozen_string_literal: true

class AddIndexOnGroupIdKindSaToAiCatalogItemConsumers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  INDEX_NAME = 'index_ai_catalog_item_consumers_on_group_id_kind_sa'

  def up
    add_concurrent_index :ai_catalog_item_consumers, [:group_id, :kind, :service_account_id],
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_item_consumers, INDEX_NAME
  end
end

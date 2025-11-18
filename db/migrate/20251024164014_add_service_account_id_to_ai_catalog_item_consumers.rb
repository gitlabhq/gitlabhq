# frozen_string_literal: true

class AddServiceAccountIdToAiCatalogItemConsumers < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :ai_catalog_item_consumers, :service_account_id, :bigint, null: true, if_not_exists: true
    end

    add_concurrent_index :ai_catalog_item_consumers, :service_account_id

    add_concurrent_foreign_key :ai_catalog_item_consumers, :users, column: :service_account_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_column :ai_catalog_item_consumers, :service_account_id, :bigint, null: true, if_exists: true
    end
  end
end

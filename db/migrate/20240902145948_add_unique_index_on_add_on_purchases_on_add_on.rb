# frozen_string_literal: true

class AddUniqueIndexOnAddOnPurchasesOnAddOn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.4'

  INDEX_NAME = 'index_add_on_purchases_on_add_on_id_and_namespace_id_null'

  def up
    add_concurrent_index :subscription_add_on_purchases,
      [:subscription_add_on_id],
      name: INDEX_NAME,
      unique: true,
      where: 'namespace_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :subscription_add_on_purchases, name: INDEX_NAME
  end
end

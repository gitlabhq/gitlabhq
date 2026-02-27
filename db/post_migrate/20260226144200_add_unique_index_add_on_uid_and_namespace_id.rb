# frozen_string_literal: true

class AddUniqueIndexAddOnUidAndNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_add_on_purchases_on_add_on_uid_and_namespace_id_not_null'

  def up
    add_concurrent_index(
      :subscription_add_on_purchases,
      [:subscription_add_on_uid, :namespace_id],
      unique: true,
      nulls_not_distinct: true,
      where: 'subscription_add_on_uid IS NOT NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :subscription_add_on_purchases, INDEX_NAME
  end
end

# frozen_string_literal: true

class DropLegacyAddOnIdIndexesFromSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  disable_ddl_transaction!

  TABLE_NAME = :subscription_add_on_purchases
  UNIQUE_NOT_NULL_INDEX_NAME = 'index_add_on_purchases_on_add_on_id_and_namespace_id_not_null'
  UNIQUE_NULL_INDEX_NAME = 'index_add_on_purchases_on_add_on_id_and_namespace_id_null'
  PLAIN_INDEX_NAME = 'idx_subscription_add_on_purchases_on_subscription_add_on_id'

  # Uniqueness is still enforced by the unique index on (subscription_add_on_uid, namespace_id).
  # index_subscription_add_on_purchases_on_namespace_id_add_on_id is kept until the column drop
  # to back the model's subscription_add_on_id uniqueness validation.
  def up
    remove_concurrent_index_by_name TABLE_NAME, UNIQUE_NOT_NULL_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, UNIQUE_NULL_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, PLAIN_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, [:subscription_add_on_id, :namespace_id],
      unique: true,
      where: 'namespace_id IS NOT NULL',
      name: UNIQUE_NOT_NULL_INDEX_NAME

    add_concurrent_index TABLE_NAME, :subscription_add_on_id,
      unique: true,
      where: 'namespace_id IS NULL',
      name: UNIQUE_NULL_INDEX_NAME

    add_concurrent_index TABLE_NAME, :subscription_add_on_id,
      name: PLAIN_INDEX_NAME
  end
end

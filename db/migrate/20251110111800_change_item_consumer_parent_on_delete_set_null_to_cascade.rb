# frozen_string_literal: true

class ChangeItemConsumerParentOnDeleteSetNullToCascade < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  def up
    remove_foreign_key(
      :ai_catalog_item_consumers, :ai_catalog_item_consumers, column: :parent_item_consumer_id, if_exists: true
    )

    add_concurrent_foreign_key(
      :ai_catalog_item_consumers, :ai_catalog_item_consumers, column: :parent_item_consumer_id, on_delete: :cascade
    )
  end

  def down
    remove_foreign_key(
      :ai_catalog_item_consumers, :ai_catalog_item_consumers, column: :parent_item_consumer_id, if_exists: true
    )

    add_concurrent_foreign_key(
      :ai_catalog_item_consumers, :ai_catalog_item_consumers, column: :parent_item_consumer_id, on_delete: :nullify
    )
  end
end

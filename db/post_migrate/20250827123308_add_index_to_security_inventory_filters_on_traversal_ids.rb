# frozen_string_literal: true

class AddIndexToSecurityInventoryFiltersOnTraversalIds < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  INDEX_NAME = 'index_security_inventory_filters_on_traversal_ids'

  def up
    add_concurrent_index :security_inventory_filters, :traversal_ids, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_inventory_filters, name: INDEX_NAME
  end
end

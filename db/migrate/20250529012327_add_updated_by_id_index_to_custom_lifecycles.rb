# frozen_string_literal: true

class AddUpdatedByIdIndexToCustomLifecycles < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  INDEX_NAME = 'index_work_item_custom_lifecycles_on_updated_by_id'

  def up
    add_concurrent_index :work_item_custom_lifecycles, :updated_by_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :work_item_custom_lifecycles, name: INDEX_NAME
  end
end

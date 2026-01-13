# frozen_string_literal: true

class AddIndexOnFoundationalFlowReference < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_catalog_items_on_foundational_flow_reference'

  def up
    add_concurrent_index :ai_catalog_items, :foundational_flow_reference, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :ai_catalog_items, :foundational_flow_reference, name: INDEX_NAME
  end
end

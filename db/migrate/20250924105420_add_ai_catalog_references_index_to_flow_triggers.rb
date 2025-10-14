# frozen_string_literal: true

class AddAiCatalogReferencesIndexToFlowTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  INDEX_NAME = 'index_ai_flow_triggers_on_ai_catalog_item_consumer_id'

  def up
    add_concurrent_index :ai_flow_triggers, :ai_catalog_item_consumer_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_item_consumer_id, INDEX_NAME
  end
end

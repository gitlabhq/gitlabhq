# frozen_string_literal: true

class AddAiCatalogReferencesFkToFlowTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    add_concurrent_foreign_key :ai_flow_triggers, :ai_catalog_item_consumers, column: :ai_catalog_item_consumer_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :ai_flow_triggers, :ai_catalog_item_consumers, column: :ai_catalog_item_consumer_id
  end
end

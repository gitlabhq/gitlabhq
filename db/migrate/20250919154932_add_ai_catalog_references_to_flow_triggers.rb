# frozen_string_literal: true

class AddAiCatalogReferencesToFlowTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    add_column :ai_flow_triggers, :ai_catalog_item_consumer_id, :bigint
  end

  def down
    remove_column :ai_flow_triggers, :ai_catalog_item_consumer_id, :bigint
  end
end

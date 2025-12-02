# frozen_string_literal: true

class AddFoundationalFlowReferenceToAiCatalogItems < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    with_lock_retries do
      add_column :ai_catalog_items, :foundational_flow_reference, :text, if_not_exists: true
    end

    add_text_limit :ai_catalog_items, :foundational_flow_reference, 255
  end

  def down
    with_lock_retries do
      remove_column :ai_catalog_items, :foundational_flow_reference, if_exists: true
    end
  end
end

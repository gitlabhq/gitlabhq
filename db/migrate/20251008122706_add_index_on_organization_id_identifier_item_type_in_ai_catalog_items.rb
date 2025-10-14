# frozen_string_literal: true

class AddIndexOnOrganizationIdIdentifierItemTypeInAiCatalogItems < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'
  INDEX_NAME = 'unique_idx_ai_catalog_items_on_org_id_identifier_item_type'
  OLD_INDEX_NAME = 'index_ai_catalog_items_on_organization_id'

  def up
    add_concurrent_index :ai_catalog_items, [:organization_id, :identifier, :item_type], name: INDEX_NAME, unique: true
    remove_concurrent_index_by_name :ai_catalog_items, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ai_catalog_items, :organization_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :ai_catalog_items, INDEX_NAME
  end
end

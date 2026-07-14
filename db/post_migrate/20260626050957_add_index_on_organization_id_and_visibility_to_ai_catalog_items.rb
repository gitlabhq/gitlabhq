# frozen_string_literal: true

class AddIndexOnOrganizationIdAndVisibilityToAiCatalogItems < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_catalog_items_on_org_id_and_visibility_not_deleted'

  def up
    add_concurrent_index :ai_catalog_items, [:organization_id, :visibility],
      name: INDEX_NAME, where: 'deleted_at IS NULL'
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_items, INDEX_NAME
  end
end

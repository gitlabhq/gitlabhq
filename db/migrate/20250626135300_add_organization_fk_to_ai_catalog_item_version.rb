# frozen_string_literal: true

class AddOrganizationFkToAiCatalogItemVersion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_concurrent_foreign_key :ai_catalog_item_versions, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_catalog_item_versions, column: :organization_id
    end
  end
end

# frozen_string_literal: true

class AddCreatedByIdForeignKeyToAiCatalogItemVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key :ai_catalog_item_versions, :users, column: :created_by_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :ai_catalog_item_versions, column: :created_by_id
  end
end

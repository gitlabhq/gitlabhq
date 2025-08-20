# frozen_string_literal: true

class AddLatestVersionToAiCatalogItem < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def change
    add_reference :ai_catalog_items, :latest_version, index: true, foreign_key: { to_table: :ai_catalog_item_versions } # rubocop:disable Migration/AddReference -- table is empty
  end
end

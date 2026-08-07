# frozen_string_literal: true

class AddFileColumnsToCatalogBundledResourceComponents < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  TABLE = :catalog_bundled_resource_components

  def up
    add_column TABLE, :file_store, :smallint, default: 1, null: false, if_not_exists: true
    add_column TABLE, :file, :text, if_not_exists: true
    add_text_limit TABLE, :file, 1024
  end

  def down
    remove_column TABLE, :file, if_exists: true
    remove_column TABLE, :file_store, if_exists: true
  end
end

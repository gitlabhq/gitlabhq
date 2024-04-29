# frozen_string_literal: true

class RemoveCatalogResourceComponentsPathColumn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  def up
    with_lock_retries do
      remove_column :catalog_resource_components, :path, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :catalog_resource_components, :path, :text, if_not_exists: true
    end

    add_text_limit :catalog_resource_components, :path, 255
  end
end

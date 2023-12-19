# frozen_string_literal: true

class AddReleasedAtToCatalogResourceVersions < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  OLD_INDEX = 'index_catalog_resource_versions_on_catalog_resource_id'
  NEW_INDEX = 'index_catalog_resource_versions_on_resource_id_and_released_at'

  def up
    # This will be denormalized with data from the `releases` table
    add_column :catalog_resource_versions, :released_at, :datetime_with_timezone, default: '1970-01-01', null: false

    remove_concurrent_index_by_name :catalog_resource_versions, OLD_INDEX
    add_concurrent_index :catalog_resource_versions, [:catalog_resource_id, :released_at], name: NEW_INDEX
  end

  def down
    remove_concurrent_index_by_name :catalog_resource_versions, NEW_INDEX
    add_concurrent_index :catalog_resource_versions, :catalog_resource_id, name: OLD_INDEX

    remove_column :catalog_resource_versions, :released_at
  end
end

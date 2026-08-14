# frozen_string_literal: true

class ReplaceCatalogBundledResourcesNaturalKeyIndex < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_catalog_bundled_resources_on_fqdn_and_full_path'
  NEW_INDEX_NAME = 'index_catalog_bundled_resources_on_server_fqdn_and_full_path'
  FQDN_CONSTRAINT = 'check_catalog_bundled_resources_fqdn_lowercase'
  PATH_CONSTRAINT = 'check_catalog_bundled_resources_full_path_lowercase'

  def up
    add_concurrent_index :catalog_bundled_resources, [:server_fqdn, :full_path],
      unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :catalog_bundled_resources, OLD_INDEX_NAME

    add_check_constraint :catalog_bundled_resources, '(server_fqdn = lower(server_fqdn))', FQDN_CONSTRAINT
    add_check_constraint :catalog_bundled_resources, '(full_path = lower(full_path))', PATH_CONSTRAINT
  end

  def down
    remove_check_constraint :catalog_bundled_resources, PATH_CONSTRAINT
    remove_check_constraint :catalog_bundled_resources, FQDN_CONSTRAINT

    add_concurrent_index :catalog_bundled_resources, 'LOWER(server_fqdn), LOWER(full_path)',
      unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :catalog_bundled_resources, NEW_INDEX_NAME
  end
end

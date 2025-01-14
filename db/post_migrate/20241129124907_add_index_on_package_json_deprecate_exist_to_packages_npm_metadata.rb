# frozen_string_literal: true

class AddIndexOnPackageJsonDeprecateExistToPackagesNpmMetadata < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  INDEX_NAME = 'index_packages_npm_metadata_on_package_json_deprecate_exist'

  def up
    add_concurrent_index :packages_npm_metadata, :package_id, where: "(package_json ? 'deprecated')", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_npm_metadata, INDEX_NAME
  end
end

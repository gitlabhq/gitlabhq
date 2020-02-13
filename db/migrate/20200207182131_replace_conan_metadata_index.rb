# frozen_string_literal: true

class ReplaceConanMetadataIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX = 'index_packages_conan_metadata_on_package_id'
  NEW_INDEX = 'index_packages_conan_metadata_on_package_id_username_channel'

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_conan_metadata,
                         [:package_id, :package_username, :package_channel],
                         unique: true, name: NEW_INDEX

    remove_concurrent_index_by_name :packages_conan_metadata, OLD_INDEX
  end

  def down
    add_concurrent_index :packages_conan_metadata, :package_id, name: OLD_INDEX

    remove_concurrent_index_by_name :packages_conan_metadata, NEW_INDEX
  end
end

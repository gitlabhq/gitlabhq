# frozen_string_literal: true

class AddForeignKeyToPackagesConanFileMetadataForPackageReference < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  INDEX_NAME = 'index_packages_conan_file_metadata_on_package_reference_id'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :packages_conan_file_metadata, :packages_conan_package_references,
      column: :package_reference_id, on_delete: :cascade
    add_concurrent_index :packages_conan_file_metadata, :package_reference_id, name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key :packages_conan_file_metadata, column: :package_reference_id
    end
    remove_concurrent_index_by_name :packages_conan_file_metadata, INDEX_NAME
  end
end

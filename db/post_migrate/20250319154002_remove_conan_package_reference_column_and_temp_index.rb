# frozen_string_literal: true

class RemoveConanPackageReferenceColumnAndTempIndex < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  TEMP_INDEX_NAME = 'tmp_index_packages_conan_file_metadata_on_id_for_migration'

  def up
    remove_concurrent_index_by_name :packages_conan_file_metadata, TEMP_INDEX_NAME
    remove_column :packages_conan_file_metadata, :conan_package_reference
  end

  def down
    add_column :packages_conan_file_metadata, :conan_package_reference, :string, limit: 255, if_not_exists: true

    add_concurrent_index(
      :packages_conan_file_metadata,
      :id,
      where: "package_reference_id IS NULL AND conan_package_reference IS NOT NULL",
      name: TEMP_INDEX_NAME
    )
  end
end

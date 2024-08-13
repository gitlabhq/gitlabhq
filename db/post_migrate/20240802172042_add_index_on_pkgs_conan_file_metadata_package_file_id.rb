# frozen_string_literal: true

class AddIndexOnPkgsConanFileMetadataPackageFileId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  INDEX_NAME = 'idx_pkgs_conan_file_metadata_on_pkg_file_id_when_recipe_file'
  RECIPE_FILE = 1

  def up
    add_concurrent_index(
      :packages_conan_file_metadata,
      :package_file_id,
      where: "conan_file_type = #{RECIPE_FILE}",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:packages_conan_file_metadata, INDEX_NAME)
  end
end

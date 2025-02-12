# frozen_string_literal: true

class AddIdxPkgsConanMetadataOnPkgFileIdWhenNullRecRev < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = 'idx_pkgs_conan_metadata_on_pkg_file_id_when_null_rec_rev'

  def up
    add_concurrent_index(
      :packages_conan_file_metadata,
      :package_file_id,
      where: 'recipe_revision_id IS NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:packages_conan_file_metadata, INDEX_NAME)
  end
end

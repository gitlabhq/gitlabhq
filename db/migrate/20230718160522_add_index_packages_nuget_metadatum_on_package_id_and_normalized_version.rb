# frozen_string_literal: true

class AddIndexPackagesNugetMetadatumOnPackageIdAndNormalizedVersion < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_packages_nuget_metadata_on_pkg_id_and_normalized_version'

  def up
    add_concurrent_index(
      :packages_nuget_metadata,
      'package_id, normalized_version',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:packages_nuget_metadata, INDEX_NAME)
  end
end

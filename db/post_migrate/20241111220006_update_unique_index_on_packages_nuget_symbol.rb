# frozen_string_literal: true

class UpdateUniqueIndexOnPackagesNugetSymbol < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  TABLE_NAME = :packages_nuget_symbols
  OLD_INDEX_NAME = :index_packages_nuget_symbols_on_signature_and_file_path
  NEW_INDEX_NAME = :idx_pkgs_nuget_symbols_on_signature_and_file_path_with_pkg_id

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[signature file_path],
      unique: true,
      name: NEW_INDEX_NAME,
      where: 'package_id IS NOT NULL'
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[signature file_path],
      unique: true,
      name: OLD_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end

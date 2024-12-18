# frozen_string_literal: true

class RemoveIndexPackagesNugetSymbolsOnSignatureAndFilepathWithPkg < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  TABLE_NAME = :packages_nuget_symbols
  INDEX_NAME = :idx_pkgs_nuget_symbols_on_signature_and_file_path_with_pkg_id

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[signature file_path],
      unique: true,
      name: INDEX_NAME,
      where: 'package_id IS NOT NULL'
    )
  end
end

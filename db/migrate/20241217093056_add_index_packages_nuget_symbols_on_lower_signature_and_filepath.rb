# frozen_string_literal: true

class AddIndexPackagesNugetSymbolsOnLowerSignatureAndFilepath < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  TABLE_NAME = :packages_nuget_symbols
  INDEX_NAME = :idx_pkgs_nuget_symbols_on_lowercase_signature_and_file_path

  def up
    add_concurrent_index TABLE_NAME, 'LOWER(signature), LOWER(file_path)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

# frozen_string_literal: true

class AddIndexPackagesNugetSymbolsOnLowercaseSignatureAndFileName < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  INDEX_NAME = 'idx_pkgs_nuget_symbols_on_lowercase_signature_and_file_name'

  def up
    add_concurrent_index :packages_nuget_symbols, 'lower(signature), lower(file)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_nuget_symbols, INDEX_NAME
  end
end

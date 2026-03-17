# frozen_string_literal: true

class AddCheckConstraintToNugetSymbolsFileSha256 < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  NUGET_SYMBOLS_TABLE = :packages_nuget_symbols
  FILE_SHA256_CONSTRAINT_NAME = 'check_packages_nuget_symbols_file_sha256_max_length'

  def up
    add_check_constraint(
      NUGET_SYMBOLS_TABLE,
      'octet_length(file_sha256) <= 64',
      FILE_SHA256_CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    remove_check_constraint(NUGET_SYMBOLS_TABLE, FILE_SHA256_CONSTRAINT_NAME)
  end
end

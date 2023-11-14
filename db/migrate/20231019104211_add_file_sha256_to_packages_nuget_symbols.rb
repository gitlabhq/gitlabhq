# frozen_string_literal: true

class AddFileSha256ToPackagesNugetSymbols < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :packages_nuget_symbols, :file_sha256, :binary
  end

  def down
    remove_column :packages_nuget_symbols, :file_sha256
  end
end

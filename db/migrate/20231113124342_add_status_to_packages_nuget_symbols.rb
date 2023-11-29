# frozen_string_literal: true

class AddStatusToPackagesNugetSymbols < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def up
    add_column :packages_nuget_symbols, :status, :smallint, null: false, default: 0
  end

  def down
    remove_column :packages_nuget_symbols, :status
  end
end

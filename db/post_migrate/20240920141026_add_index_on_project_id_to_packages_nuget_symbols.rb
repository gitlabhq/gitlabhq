# frozen_string_literal: true

class AddIndexOnProjectIdToPackagesNugetSymbols < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  INDEX_NAME = :index_packages_nuget_symbols_on_project_id

  def up
    add_concurrent_index :packages_nuget_symbols, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_nuget_symbols, INDEX_NAME
  end
end

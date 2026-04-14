# frozen_string_literal: true

class IndexPackagesNugetSymbolStatesOnProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_nuget_symbol_states_on_project_id'

  def up
    add_concurrent_index :packages_nuget_symbol_states, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_nuget_symbol_states, INDEX_NAME
  end
end

# frozen_string_literal: true

class AddPackagesNugetSymbolStatesProjectIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :packages_nuget_symbol_states,
      sharding_key: :project_id,
      parent_table: :packages_nuget_symbols,
      parent_sharding_key: :project_id,
      foreign_key: :packages_nuget_symbol_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :packages_nuget_symbol_states,
      sharding_key: :project_id,
      parent_table: :packages_nuget_symbols,
      parent_sharding_key: :project_id,
      foreign_key: :packages_nuget_symbol_id
    )
  end
end

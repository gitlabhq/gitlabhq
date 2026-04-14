# frozen_string_literal: true

class AddProjectIdToPackagesNugetSymbolStates < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :packages_nuget_symbol_states, :project_id, :bigint
  end
end

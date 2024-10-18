# frozen_string_literal: true

class AddProjectIdToPackagesNugetSymbols < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :packages_nuget_symbols, :project_id, :bigint
  end
end

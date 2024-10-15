# frozen_string_literal: true

class AddProjectIdToPackagesNugetMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :packages_nuget_metadata, :project_id, :bigint
  end
end

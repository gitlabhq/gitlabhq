# frozen_string_literal: true

class AddProjectIdToPackagesNugetDependencyLinkMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :packages_nuget_dependency_link_metadata, :project_id, :bigint
  end
end

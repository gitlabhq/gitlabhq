# frozen_string_literal: true

class AddIndexOnNameVersionPatternToPackagesDependenciesWithProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    add_concurrent_index(
      :packages_dependencies,
      %i[name version_pattern project_id],
      unique: true,
      name: :index_packages_dependencies_on_name_version_pattern_project_id,
      where: 'project_id IS NOT NULL'
    )
  end

  def down
    remove_concurrent_index_by_name(
      :packages_dependencies,
      :index_packages_dependencies_on_name_version_pattern_project_id
    )
  end
end

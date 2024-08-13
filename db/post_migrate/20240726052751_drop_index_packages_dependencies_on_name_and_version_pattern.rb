# frozen_string_literal: true

class DropIndexPackagesDependenciesOnNameAndVersionPattern < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    remove_concurrent_index_by_name(
      :packages_dependencies,
      :index_packages_dependencies_on_name_and_version_pattern
    )
  end

  def down
    add_concurrent_index(
      :packages_dependencies,
      %i[name version_pattern],
      unique: true,
      name: :index_packages_dependencies_on_name_and_version_pattern
    )
  end
end

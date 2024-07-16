# frozen_string_literal: true

class RemoveIndexPackagesPackagesOnProjectIdAndLowerNameToPackages < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  INDEX_NAME = 'index_packages_packages_on_project_id_and_lower_name'
  NUGET_PACKAGE_TYPE = 4

  def up
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :packages_packages,
      'project_id, LOWER(name)',
      name: INDEX_NAME,
      where: "package_type = #{NUGET_PACKAGE_TYPE}"
    )
  end
end

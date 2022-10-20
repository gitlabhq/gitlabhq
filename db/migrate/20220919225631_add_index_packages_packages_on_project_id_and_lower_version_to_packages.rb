# frozen_string_literal: true

class AddIndexPackagesPackagesOnProjectIdAndLowerVersionToPackages < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_packages_on_project_id_and_lower_version'
  NUGET_PACKAGE_TYPE = 4

  def up
    add_concurrent_index(
      :packages_packages,
      'project_id, LOWER(version)',
      name: INDEX_NAME,
      where: "package_type = #{NUGET_PACKAGE_TYPE}"
    )
  end

  def down
    remove_concurrent_index_by_name(:packages_packages, INDEX_NAME)
  end
end

# frozen_string_literal: true

class AddUniqueIndexForNpmPackagesOnProjectIdNameVersion < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_packages_on_project_id_name_version_unique_when_npm'
  PACKAGE_TYPE_NPM = 2

  def up
    add_concurrent_index(
      :packages_packages,
      %i[project_id name version],
      name: INDEX_NAME,
      unique: true,
      where: "package_type = #{PACKAGE_TYPE_NPM} AND status <> 4"
    )
  end

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end

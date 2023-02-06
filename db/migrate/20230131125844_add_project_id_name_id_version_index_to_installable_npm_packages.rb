# frozen_string_literal: true

class AddProjectIdNameIdVersionIndexToInstallableNpmPackages < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_packages_on_project_id_name_id_version_when_installable_npm'
  PACKAGE_TYPE_NPM = 2

  def up
    add_concurrent_index(
      :packages_packages,
      [:project_id, :name, :id, :version],
      name: INDEX_NAME,
      where: "package_type = #{PACKAGE_TYPE_NPM} AND status IN (0, 1)"
    )
  end

  def down
    remove_concurrent_index_by_name(:packages_packages, INDEX_NAME)
  end
end

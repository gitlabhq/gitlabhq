# frozen_string_literal: true

class AddProjectIdNameVersionIdIndexToInstallableTerraformModules < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_pkgs_on_project_id_name_version_on_installable_terraform'
  PACKAGE_TYPE_TERRAFORM_MODULE = 12
  INSTALLABLE_CONDITION = 'status IN (0, 1)'

  def up
    add_concurrent_index(
      :packages_packages,
      %i[project_id name version id],
      name: INDEX_NAME,
      where: "package_type = #{PACKAGE_TYPE_TERRAFORM_MODULE} AND #{INSTALLABLE_CONDITION}"
    )
  end

  def down
    remove_concurrent_index_by_name(:packages_packages, INDEX_NAME)
  end
end

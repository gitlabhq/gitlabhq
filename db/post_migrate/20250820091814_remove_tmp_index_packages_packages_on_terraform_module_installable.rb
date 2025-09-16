# frozen_string_literal: true

class RemoveTmpIndexPackagesPackagesOnTerraformModuleInstallable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  INDEX_NAME = 'tmp_idx_pkgs_pkgs_on_id_when_terraform_module_installable'
  TERRAFORM_MODULE_PACKAGE_TYPE = 12
  INSTALLABLE_STATUS = '(0, 1)'

  def up
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :packages_packages,
      :id,
      where: "package_type = #{TERRAFORM_MODULE_PACKAGE_TYPE} AND status IN #{INSTALLABLE_STATUS}",
      name: INDEX_NAME
    )
  end
end

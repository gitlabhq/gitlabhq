# frozen_string_literal: true

class AddInstallableConanPackagesIndexToPackages < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_installable_conan_pkgs_on_project_id_id'
  # as defined by Packages::Package.package_types
  CONAN_PACKAGE_TYPE = 3

  # as defined by Packages::Package::INSTALLABLE_STATUSES
  DEFAULT_STATUS = 0
  HIDDEN_STATUS = 1

  def up
    where = "package_type = #{CONAN_PACKAGE_TYPE} AND status IN (#{DEFAULT_STATUS}, #{HIDDEN_STATUS})"
    add_concurrent_index :packages_packages,
                         [:project_id, :id],
                         where: where,
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end

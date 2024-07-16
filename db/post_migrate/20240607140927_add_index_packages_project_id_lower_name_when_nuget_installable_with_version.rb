# frozen_string_literal: true

class AddIndexPackagesProjectIdLowerNameWhenNugetInstallableWithVersion < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  INDEX_NAME = 'idx_pkgs_project_id_lower_name_when_nuget_installable_version'
  NUGET_TYPE = 'package_type = 4'
  WITH_VERSION = 'version IS NOT NULL'
  INSTALLABLE_STATUS = 'status IN (0, 1)'

  def up
    add_concurrent_index :packages_packages, 'project_id, LOWER(name)', # rubocop:disable Migration/PreventIndexCreation -- I'm replicating an existing index with a more selective where clause
      where: "#{NUGET_TYPE} AND #{WITH_VERSION} AND #{INSTALLABLE_STATUS}",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_packages, name: INDEX_NAME
  end
end

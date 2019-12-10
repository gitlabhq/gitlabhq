# frozen_string_literal: true

class AddProjectIdNameVersionPackageTypeIndexToPackagesPackages < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_packages_packages_on_project_id_name_version_package_type'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_packages,
                         [:project_id, :name, :version, :package_type],
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index :packages_packages,
                            [:project_id, :name, :version, :package_type],
                            name: INDEX_NAME
  end
end

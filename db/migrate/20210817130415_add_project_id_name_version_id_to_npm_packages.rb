# frozen_string_literal: true

class AddProjectIdNameVersionIdToNpmPackages < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'idx_installable_npm_pkgs_on_project_id_name_version_id'

  def up
    add_concurrent_index :packages_packages, [:project_id, :name, :version, :id], where: 'package_type = 2 AND status = 0', name: INDEX_NAME
  end

  def down
    remove_concurrent_index :packages_packages, [:project_id, :name, :version, :id], where: 'package_type = 2 AND status = 0', name: INDEX_NAME
  end
end

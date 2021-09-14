# frozen_string_literal: true

class AddInstallableHelmPkgsIdxToPackages < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'idx_installable_helm_pkgs_on_project_id_id'

  def up
    add_concurrent_index :packages_packages, [:project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :packages_packages, [:project_id, :id], name: INDEX_NAME
  end
end

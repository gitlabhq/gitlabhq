# frozen_string_literal: true

class AddSortingIndexToPackages < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_packages, [:project_id, :created_at]
    add_concurrent_index :packages_packages, [:project_id, :version]
    add_concurrent_index :packages_packages, [:project_id, :package_type]
  end

  def down
    remove_concurrent_index :packages_packages, [:project_id, :created_at]
    remove_concurrent_index :packages_packages, [:project_id, :version]
    remove_concurrent_index :packages_packages, [:project_id, :package_type]
  end
end

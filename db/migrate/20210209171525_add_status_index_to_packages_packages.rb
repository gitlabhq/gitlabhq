# frozen_string_literal: true

class AddStatusIndexToPackagesPackages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_packages_on_project_id_and_status'

  def up
    add_concurrent_index :packages_packages, [:project_id, :status], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_packages, name: INDEX_NAME
  end
end

# frozen_string_literal: true

class RemoveProjectIdIndexFromPackages < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :packages_packages, [:project_id]
  end

  def down
    add_concurrent_index :packages_packages, [:project_id]
  end
end

# frozen_string_literal: true

class AddNameIndexToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds,
      [:name],
      name: 'index_ci_builds_on_name_for_security_products_values',
      where: "name IN ('container_scanning','dast','dependency_scanning','license_management','sast')"
  end

  def down
    remove_concurrent_index :ci_builds, [:name], name: 'index_ci_builds_on_name_for_security_products_values'
  end
end

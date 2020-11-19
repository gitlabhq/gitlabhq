# frozen_string_literal: true

class UpdatePackagesBuildInfosIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  NEW_INDEX_NAME = 'idx_packages_build_infos_on_package_id'
  OLD_INDEX_NAME = 'index_packages_build_infos_on_package_id'

  def up
    add_concurrent_index :packages_build_infos, :package_id, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :packages_build_infos, OLD_INDEX_NAME
  end

  def down
    # No op. It is possible records would validate the UNIQUE constraint, so it
    # cannot be added back to the index.
  end
end

# frozen_string_literal: true

class AddIdForCleanupIndexPackagesPackageFiles < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_package_files_on_id_for_cleanup'

  PACKAGE_FILE_STATUS_PENDING_DESTRUCTION = 1

  def up
    where = "status = #{PACKAGE_FILE_STATUS_PENDING_DESTRUCTION}"

    add_concurrent_index :packages_package_files, :id, name: INDEX_NAME, where: where
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, name: INDEX_NAME
  end
end

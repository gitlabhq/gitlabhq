# frozen_string_literal: true

class DropTmpIdxPackageFilesOnNonZeroSize < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_package_files_on_non_zero_size'

  def up
    remove_concurrent_index :packages_package_files, %i[package_id size], name: INDEX_NAME
  end

  def down
    add_concurrent_index :packages_package_files, %i[package_id size], where: 'size IS NOT NULL', name: INDEX_NAME
  end
end

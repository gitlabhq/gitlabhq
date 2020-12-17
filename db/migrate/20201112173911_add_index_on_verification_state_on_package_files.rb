# frozen_string_literal: true

class AddIndexOnVerificationStateOnPackageFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_packages_package_files_on_verification_state'

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_package_files, :verification_state, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, INDEX_NAME
  end
end

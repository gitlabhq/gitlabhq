# frozen_string_literal: true

class AddChecksumIndexToPackageFile < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_package_files, :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: "packages_packages_verification_checksum_partial"
  end

  def down
    remove_concurrent_index :packages_package_files, :verification_checksum
  end
end

# frozen_string_literal: true

class AddFkPackagesPypiFileMetadataPackagesPackageFiles < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key :packages_pypi_file_metadata, :packages_package_files,
      column: :package_file_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :packages_pypi_file_metadata, :packages_package_files, column: :package_file_id
    end
  end
end

# frozen_string_literal: true

class AddFileFinalPathToPackagesPackageFiles < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  def up
    with_lock_retries do
      add_column :packages_package_files, :file_final_path, :text, if_not_exists: true
    end

    add_text_limit :packages_package_files, :file_final_path, 1024
  end

  def down
    with_lock_retries do
      remove_column :packages_package_files, :file_final_path, if_exists: true
    end
  end
end

class CreatePackagesPackageFiles < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :packages_package_files do |t|
      t.references :package, index: true, null: false
      t.string :file
      t.string :file_name, null: false
      t.integer :file_type
      t.integer :file_store
      t.integer :size
      t.binary :file_md5
      t.binary :file_sha1

      t.timestamps_with_timezone null: false
    end

    add_concurrent_foreign_key :packages_package_files, :packages_packages,
      column: :package_id,
      on_delete: :cascade
  end

  def down
    if foreign_keys_for(:packages_package_files, :package_id).any?
      remove_foreign_key :packages_package_files, column: :package_id
    end

    if table_exists?(:packages_package_files)
      drop_table :packages_package_files
    end
  end
end

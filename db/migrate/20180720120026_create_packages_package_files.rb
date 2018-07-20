class CreatePackagesPackageFiles < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :packages_package_files do |t|
      t.references :package, index: true, foreign_key: true, null: false
      t.string :file
      t.integer :file_type
      t.integer :size
      t.binary :file_md5
      t.binary :file_sha1

      t.timestamps null: false
    end
  end
end

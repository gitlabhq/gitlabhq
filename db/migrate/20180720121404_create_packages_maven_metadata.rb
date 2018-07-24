class CreatePackagesMavenMetadata < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :packages_maven_metadata do |t|
      t.references :package, index: true, null: false
      t.string :app_group, null: false
      t.string :app_name, null: false
      t.string :app_version, null: false

      t.timestamps null: false
    end

    add_concurrent_foreign_key :packages_maven_metadata, :packages_packages,
      column: :package_id,
      on_delete: :cascade
  end
end

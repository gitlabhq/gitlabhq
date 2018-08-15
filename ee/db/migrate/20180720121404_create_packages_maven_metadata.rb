# frozen_string_literal: true
class CreatePackagesMavenMetadata < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :packages_maven_metadata, id: :bigserial do |t|
      t.references :package, type: :bigint, null: false

      t.timestamps_with_timezone null: false

      t.string :app_group, null: false
      t.string :app_name, null: false
      t.string :app_version
      t.string :path, limit: 512, null: false
    end

    add_concurrent_index :packages_maven_metadata, [:package_id, :path]

    add_concurrent_foreign_key :packages_maven_metadata, :packages_packages,
      column: :package_id,
      on_delete: :cascade
  end

  def down
    if foreign_keys_for(:packages_maven_metadata, :package_id).any?
      remove_foreign_key :packages_maven_metadata, column: :package_id
    end

    if index_exists?(:packages_maven_metadata, [:package_id, :path])
      remove_concurrent_index :packages_maven_metadata, [:package_id, :path]
    end

    if table_exists?(:packages_maven_metadata)
      drop_table :packages_maven_metadata
    end
  end
end

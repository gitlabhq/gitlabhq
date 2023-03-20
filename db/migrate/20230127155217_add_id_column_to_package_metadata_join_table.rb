# frozen_string_literal: true

class AddIdColumnToPackageMetadataJoinTable < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  COMPOSITE_UNIQUE_INDEX = :i_pm_package_version_licenses_join_ids

  def up
    if Gitlab::Database::PostgresPartitionedTable.where(name: 'pm_package_version_licenses').exists?
      recreate_unpartitioned_tables
    end

    drop_constraint(:pm_package_version_licenses, :pm_package_version_licenses_pkey, cascade: true)
    add_column(:pm_package_version_licenses, :id, :primary_key)
    add_concurrent_index(:pm_package_version_licenses, [:pm_package_version_id, :pm_license_id], unique: true,
      name: COMPOSITE_UNIQUE_INDEX)
  end

  def down
    return if Gitlab::Database::PostgresPartitionedTable.where(name: 'pm_package_version_licenses').exists?

    remove_column(:pm_package_version_licenses, :id)
    add_primary_key_using_index(:pm_package_version_licenses, :pm_package_version_licenses_pkey, COMPOSITE_UNIQUE_INDEX)
    remove_concurrent_index_by_name(:pm_package_version_licenses, COMPOSITE_UNIQUE_INDEX)
  end

  private

  def recreate_unpartitioned_tables
    drop_table(:pm_package_version_licenses, force: :cascade) # rubocop:disable Migration/DropTable
    drop_table(:pm_package_versions, force: :cascade) # rubocop:disable Migration/DropTable
    drop_table(:pm_packages, force: :cascade) # rubocop:disable Migration/DropTable

    create_table :pm_packages do |t|
      t.integer :purl_type, limit: 2, null: false
      t.text :name, null: false, limit: 255
      t.timestamps_with_timezone null: false
      t.index [:purl_type, :name], name: 'i_pm_packages_purl_type_and_name', unique: true
    end

    create_table :pm_package_versions do |t|
      t.references :pm_package,
        index: false,
        null: false,
        foreign_key: {
          to_table: :pm_packages,
          column: :pm_package_id,
          name: 'fk_rails_cf94c3e601',
          on_delete: :cascade
        }
      t.text :version, null: false, limit: 255
      t.timestamps_with_timezone null: false
      t.index [:pm_package_id, :version], name: 'i_pm_package_versions_on_package_id_and_version', unique: true
      t.index :pm_package_id, name: 'index_pm_package_versions_on_pm_package_id'
    end

    create_table :pm_package_version_licenses, primary_key: [:pm_package_version_id, :pm_license_id] do |t|
      t.references :pm_package_version,
        index: false,
        null: false,
        foreign_key: {
          to_table: :pm_package_versions,
          column: :pm_package_version_id,
          name: 'fk_rails_30ddb7f837',
          on_delete: :cascade
        }
      t.references :pm_license,
        index: false,
        null: false,
        foreign_key: { name: 'fk_rails_7520ea026d', on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.index :pm_license_id, name: 'index_pm_package_version_licenses_on_pm_license_id'
      t.index :pm_package_version_id, name: 'index_pm_package_version_licenses_on_pm_package_version_id'
    end
  end
end

# frozen_string_literal: true

class AddIdColumnToPackageMetadataJoinTable < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  COMPOSITE_UNIQUE_INDEX = :i_pm_package_version_licenses_join_ids

  def up
    drop_constraint(:pm_package_version_licenses, :pm_package_version_licenses_pkey, cascade: true)
    add_column(:pm_package_version_licenses, :id, :primary_key)
    add_concurrent_index(:pm_package_version_licenses, [:pm_package_version_id, :pm_license_id], unique: true,
      name: COMPOSITE_UNIQUE_INDEX)
  end

  def down
    remove_column(:pm_package_version_licenses, :id)
    add_primary_key_using_index(:pm_package_version_licenses, :pm_package_version_licenses_pkey, COMPOSITE_UNIQUE_INDEX)
    remove_concurrent_index_by_name(:pm_package_version_licenses, COMPOSITE_UNIQUE_INDEX)
  end
end

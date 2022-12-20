# frozen_string_literal: true

class CreatePackageMetadataPackageVersionLicenses < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'i_pm_package_version_licenses_on_version_and_license_ids'

  def change
    create_table :pm_package_version_licenses, primary_key: [:pm_package_version_id, :pm_license_id] do |t|
      t.references :pm_package_version, foreign_key: { on_delete: :cascade }, null: false
      t.references :pm_license, foreign_key: { on_delete: :cascade }, null: false
    end
  end
end

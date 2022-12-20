# frozen_string_literal: true

class CreatePackageMetadataVersions < Gitlab::Database::Migration[2.0]
  def change
    create_table :pm_package_versions do |t|
      t.references :pm_package, foreign_key: { to_table: :pm_packages, on_delete: :cascade }
      t.text :version, null: false, limit: 255
      t.index [:pm_package_id, :version], unique: true, name: 'i_pm_package_versions_on_package_id_and_version'
    end
  end
end

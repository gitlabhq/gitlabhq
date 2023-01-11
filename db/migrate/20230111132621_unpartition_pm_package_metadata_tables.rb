# frozen_string_literal: true

class UnpartitionPmPackageMetadataTables < Gitlab::Database::Migration[2.1]
  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.staging?

    drop_table(:pm_package_version_licenses, force: :cascade) # rubocop:disable Migration/DropTable
    drop_table(:pm_package_versions, force: :cascade) # rubocop:disable Migration/DropTable
    drop_table(:pm_packages, force: :cascade) # rubocop:disable Migration/DropTable

    create_table :pm_packages do |t|
      t.integer :purl_type, limit: 2, null: false
      t.text :name, null: false, limit: 255
      t.index [:purl_type, :name], name: 'i_pm_packages_purl_type_and_name', unique: true
    end

    create_table :pm_package_versions do |t|
      t.references :pm_package,
        index: false,
        foreign_key: {
          to_table: :pm_packages,
          column: :pm_package_id,
          name: 'fk_rails_cf94c3e601',
          on_delete: :cascade
        }
      t.text :version, null: false, limit: 255
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
      t.index :pm_license_id, name: 'index_pm_package_version_licenses_on_pm_license_id'
      t.index :pm_package_version_id, name: 'index_pm_package_version_licenses_on_pm_package_version_id'
    end
  end

  # partitioned tables can't be restored because
  # foreign keys to partitioned tables are not supported by Postgres 11
  # https://gitlab.com/gitlab-org/gitlab/-/issues/387761
  def down; end
end

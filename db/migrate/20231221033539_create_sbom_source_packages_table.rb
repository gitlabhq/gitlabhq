# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateSbomSourcePackagesTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  SBOM_SOURCE_PACKAGES_INDEX_NAME = 'idx_sbom_source_packages_on_name_and_purl_type'
  SBOM_OCCURRENCES_SOURCE_PACKAGE_ID_AND_ID_INDEX_NAME = 'index_sbom_source_packages_on_source_package_id_and_id'

  def up
    with_lock_retries do
      add_column :sbom_occurrences, :source_package_id, :bigint, if_not_exists: true
    end

    create_table :sbom_source_packages, if_not_exists: true do |t|
      t.text :name, null: false, limit: 255
      t.integer :purl_type, limit: 2, null: false
      t.index [:name, :purl_type], unique: true, name: SBOM_SOURCE_PACKAGES_INDEX_NAME
    end

    add_concurrent_index :sbom_occurrences, [:source_package_id, :id],
      name: SBOM_OCCURRENCES_SOURCE_PACKAGE_ID_AND_ID_INDEX_NAME

    add_concurrent_foreign_key :sbom_occurrences, :sbom_source_packages,
      column: :source_package_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :sbom_occurrences,
        column: :source_package_id,
        on_delete: :cascade
      )
      remove_column :sbom_occurrences, :source_package_id, if_exists: true
      drop_table :sbom_source_packages, if_exists: true
    end
  end
end

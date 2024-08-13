# frozen_string_literal: true

class AddOrganizationToSbomSources < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  INDEX_NAME = 'index_sbom_sources_on_organization_id'

  def up
    with_lock_retries do
      add_column :sbom_sources, :organization_id, :bigint, null: false,
        default: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
        if_not_exists: true
    end

    add_concurrent_foreign_key :sbom_sources, :organizations, column: :organization_id, on_delete: :cascade
    add_concurrent_index :sbom_sources, :organization_id, name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key :sbom_sources, column: :organization_id
    end

    remove_concurrent_index_by_name :sbom_sources, INDEX_NAME

    with_lock_retries do
      remove_column :sbom_sources, :organization_id, if_exists: true
    end
  end
end

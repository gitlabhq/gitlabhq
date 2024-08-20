# frozen_string_literal: true

class AddOrganizationToSbomComponents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  INDEX_NAME = 'index_sbom_components_on_organization_id'

  def up
    with_lock_retries do
      add_column :sbom_components, :organization_id, :bigint, null: false,
        default: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
        if_not_exists: true
    end

    add_concurrent_index :sbom_components, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_components, INDEX_NAME

    with_lock_retries do
      remove_column :sbom_components, :organization_id, if_exists: true
    end
  end
end

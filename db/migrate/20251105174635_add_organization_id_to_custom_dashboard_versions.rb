# frozen_string_literal: true

class AddOrganizationIdToCustomDashboardVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  INDEX_NAME = 'index_custom_dashboard_versions_on_organization_id'

  def up
    # rubocop:disable Rails/NotNullColumn -- table is empty
    add_column :custom_dashboard_versions, :organization_id, :bigint, null: false, if_not_exists: true

    add_concurrent_index :custom_dashboard_versions, :organization_id, name: INDEX_NAME

    add_concurrent_foreign_key :custom_dashboard_versions, :organizations,
      column: :organization_id, on_delete: :cascade
    # rubocop:enable Rails/NotNullColumn
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :custom_dashboard_versions, column: :organization_id
    end

    remove_concurrent_index_by_name :custom_dashboard_versions, INDEX_NAME

    remove_column :custom_dashboard_versions, :organization_id, if_exists: true
  end
end

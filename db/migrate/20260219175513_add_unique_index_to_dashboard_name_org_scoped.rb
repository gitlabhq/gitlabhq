# frozen_string_literal: true

class AddUniqueIndexToDashboardNameOrgScoped < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.10'

  INDEX_NAME = 'idx_unique_dashboard_name_org_namespace'
  OLD_INDEX_NAME = 'index_custom_dashboards_on_organization_id'

  def up
    add_concurrent_index :custom_dashboards,
      [:organization_id, :namespace_id, :name],
      unique: true,
      nulls_not_distinct: true,
      name: INDEX_NAME

    # The new composite index on (organization_id, namespace_id, name)
    # covers queries filtering by organization_id due to left-prefix indexing.
    # The existing index on (organization_id) becomes redundant and is removed
    # to avoid duplicate index coverage
    remove_concurrent_index_by_name :custom_dashboards, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :custom_dashboards,
      [:organization_id],
      name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :custom_dashboards, INDEX_NAME
  end
end

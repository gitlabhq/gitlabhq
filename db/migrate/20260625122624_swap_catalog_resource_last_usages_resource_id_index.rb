# frozen_string_literal: true

class SwapCatalogResourceLastUsagesResourceIdIndex < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  TABLE_NAME = :catalog_resource_component_last_usages
  NEW_INDEX_NAME = 'index_last_usages_on_resource_id_date_and_used_by_project'
  OLD_INDEX_NAME = 'idx_cpmt_last_usages_on_catalog_resource_id'
  NEW_COLUMNS = %i[catalog_resource_id last_used_date used_by_project_id]

  def up
    # Covering index for the per-resource aggregation in
    # Ci::Catalog::Resources::AggregateLast30DayUsageService. Leading with
    # catalog_resource_id keeps the fk_4adc9539c0 foreign key covered, so the
    # old single-column index becomes redundant and is removed below.
    add_concurrent_index TABLE_NAME, NEW_COLUMNS, name: NEW_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :catalog_resource_id, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
  end
end

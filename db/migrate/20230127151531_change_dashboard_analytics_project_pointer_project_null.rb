# frozen_string_literal: true

class ChangeDashboardAnalyticsProjectPointerProjectNull < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  EXISTENCE_CONSTRAINT = 'chk_analytics_dashboards_pointers_project_or_namespace'
  NEW_UNIQ_INDEX = 'idx_uniq_analytics_dashboards_pointers_on_project_id'
  OLD_INDEX = 'index_analytics_dashboards_pointers_on_project_id'

  def up
    add_check_constraint :analytics_dashboards_pointers,
                         "(project_id IS NULL) <> (namespace_id IS NULL)",
                         EXISTENCE_CONSTRAINT

    change_column_null :analytics_dashboards_pointers, :target_project_id, false

    add_concurrent_index :analytics_dashboards_pointers, :project_id, name: NEW_UNIQ_INDEX, unique: true
    remove_concurrent_index_by_name :analytics_dashboards_pointers, OLD_INDEX
  end

  def down
    remove_check_constraint :analytics_dashboards_pointers, EXISTENCE_CONSTRAINT

    change_column_null :analytics_dashboards_pointers, :target_project_id, true

    add_concurrent_index :analytics_dashboards_pointers, :project_id, name: OLD_INDEX
    remove_concurrent_index_by_name :analytics_dashboards_pointers, NEW_UNIQ_INDEX
  end
end

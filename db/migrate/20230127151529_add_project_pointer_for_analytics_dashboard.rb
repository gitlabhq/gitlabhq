# frozen_string_literal: true

class AddProjectPointerForAnalyticsDashboard < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    change_column_null :analytics_dashboards_pointers, :project_id, true
    change_column_null :analytics_dashboards_pointers, :namespace_id, true

    unless column_exists?(:analytics_dashboards_pointers, :target_project_id)
      add_column :analytics_dashboards_pointers, :target_project_id, :bigint
    end

    add_concurrent_foreign_key :analytics_dashboards_pointers, :projects,
                               column: :target_project_id,
                               on_delete: :cascade

    add_concurrent_index :analytics_dashboards_pointers, :target_project_id
  end

  def down
    change_column_null :analytics_dashboards_pointers, :project_id, false
    change_column_null :analytics_dashboards_pointers, :namespace_id, false

    return unless column_exists?(:analytics_dashboards_pointers, :target_project_id)

    remove_column :analytics_dashboards_pointers, :target_project_id
  end
end

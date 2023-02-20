# frozen_string_literal: true

class MigrateProjectPointerForAnalyticsDashboard < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute 'UPDATE analytics_dashboards_pointers SET target_project_id = project_id'
    execute 'UPDATE analytics_dashboards_pointers SET project_id = NULL'
  end

  def down
    execute 'UPDATE analytics_dashboards_pointers SET project_id = target_project_id'
    execute 'UPDATE analytics_dashboards_pointers SET target_project_id = NULL'
  end
end

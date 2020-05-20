# frozen_string_literal: true

class AddTextLimitToMetricsUsersStarredDashboardsDashboardPath < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_text_limit :metrics_users_starred_dashboards, :dashboard_path, 255
  end

  def down
    remove_text_limit :metrics_users_starred_dashboards, :dashboard_path
  end
end

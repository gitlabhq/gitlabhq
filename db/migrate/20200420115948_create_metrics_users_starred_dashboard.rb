# frozen_string_literal: true

class CreateMetricsUsersStarredDashboard < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # limit added in following migration db/migrate/20200424101920_add_text_limit_to_metrics_users_starred_dashboards_dashboard_path.rb
  # to allow this migration to be run inside the transaction
  # rubocop: disable Migration/AddLimitToTextColumns
  def up
    create_table :metrics_users_starred_dashboards do |t|
      t.timestamps_with_timezone
      t.bigint :project_id, null: false
      t.bigint :user_id, null: false
      t.text :dashboard_path, null: false

      t.index :project_id
      t.index %i(user_id project_id dashboard_path), name: "idx_metrics_users_starred_dashboard_on_user_project_dashboard", unique: true
    end
  end
  # rubocop: enable Migration/AddLimitToTextColumns

  def down
    drop_table :metrics_users_starred_dashboards
  end
end

# frozen_string_literal: true

class AddDashboardLimitToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :dashboard_limit_enabled, :boolean, default: false, null: false
    add_column :application_settings, :dashboard_limit, :integer, default: 0, null: false
    add_column :application_settings, :dashboard_notification_limit, :integer, default: 0, null: false
    add_column :application_settings, :dashboard_enforcement_limit, :integer, default: 0, null: false
    add_column :application_settings, :dashboard_limit_new_namespace_creation_enforcement_date, :date
  end
end

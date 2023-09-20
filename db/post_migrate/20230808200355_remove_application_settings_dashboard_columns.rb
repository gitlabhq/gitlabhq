# frozen_string_literal: true

class RemoveApplicationSettingsDashboardColumns < Gitlab::Database::Migration[2.1]
  def change
    remove_column :application_settings, :dashboard_enforcement_limit, :integer, default: 0, null: false
    remove_column :application_settings, :dashboard_limit_new_namespace_creation_enforcement_date, :date
  end
end

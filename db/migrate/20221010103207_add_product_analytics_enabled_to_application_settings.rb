# frozen_string_literal: true

class AddProductAnalyticsEnabledToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :product_analytics_enabled, :boolean, default: false, null: false
  end
end

# frozen_string_literal: true

class AddProductAnalyticsEnabledToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  def change
    add_column :namespace_settings, :product_analytics_enabled, :boolean, default: false, null: false
  end
end

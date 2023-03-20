# frozen_string_literal: true

class AddProductAnalyticsDataCollectorHostToApplicationSettings < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_column :application_settings, :product_analytics_data_collector_host, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

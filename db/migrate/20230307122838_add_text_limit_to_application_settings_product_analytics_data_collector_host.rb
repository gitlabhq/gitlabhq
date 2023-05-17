# frozen_string_literal: true

class AddTextLimitToApplicationSettingsProductAnalyticsDataCollectorHost < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :product_analytics_data_collector_host, 255
  end

  def down
    remove_text_limit :application_settings, :product_analytics_data_collector_host
  end
end

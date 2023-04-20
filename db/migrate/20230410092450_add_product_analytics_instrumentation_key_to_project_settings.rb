# frozen_string_literal: true

class AddProductAnalyticsInstrumentationKeyToProjectSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230413153140_add_text_limit_to_project_settings_instrumentation_key.rb
  def up
    with_lock_retries do
      add_column :project_settings, :product_analytics_instrumentation_key, :text unless
        column_exists?(:project_settings, :product_analytics_instrumentation_key)
    end
  end

  def down
    with_lock_retries do
      remove_column :project_settings, :product_analytics_instrumentation_key
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

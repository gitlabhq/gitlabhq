# frozen_string_literal: true

class AddTextLimitToProjectSettingsInstrumentationKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :project_settings, :product_analytics_instrumentation_key, 255
  end

  def down
    remove_text_limit :project_settings, :product_analytics_instrumentation_key
  end
end

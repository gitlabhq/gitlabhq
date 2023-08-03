# frozen_string_literal: true

class AddTextLimitToGoogleCloudLoggingConfigurationName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :audit_events_google_cloud_logging_configurations, :name, 72
  end

  def down
    remove_text_limit :audit_events_google_cloud_logging_configurations, :name
  end
end

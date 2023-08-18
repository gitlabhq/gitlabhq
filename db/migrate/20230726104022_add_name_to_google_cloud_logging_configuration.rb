# frozen_string_literal: true

class AddNameToGoogleCloudLoggingConfiguration < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # text limit is added in a 20230726104547_add_text_limit_to_google_cloud_logging_configuration_name.rb migration
  def change
    add_column :audit_events_google_cloud_logging_configurations, :name, :text
  end

  # rubocop:enable Migration/AddLimitToTextColumns
end

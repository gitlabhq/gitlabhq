# frozen_string_literal: true

class AddDatabaseGrafanaConfigToApplicationSettings < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220307002607_add_text_limit_to_db_reindexing_grafana_application_settings
  def change
    add_column :application_settings, :encrypted_database_grafana_api_key, :binary
    add_column :application_settings, :encrypted_database_grafana_api_key_iv, :binary
    add_column :application_settings, :database_grafana_api_url, :text
    add_column :application_settings, :database_grafana_tag, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

# frozen_string_literal: true

class AddTextLimitToDatabaseGrafanaApplicationSettings < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :database_grafana_api_url, 255
    add_text_limit :application_settings, :database_grafana_tag, 255
  end

  def down
    remove_text_limit :application_settings, :database_grafana_tag
    remove_text_limit :application_settings, :database_grafana_api_url
  end
end

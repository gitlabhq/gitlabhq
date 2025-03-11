# frozen_string_literal: true

class RemoveProductUsageDataEnabledFromServicePingSettings < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.10'
  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    application_settings = ApplicationSetting.where("service_ping_settings ? 'product_usage_data_enabled'")

    application_settings.find_each do |setting|
      service_ping_settings = setting.service_ping_settings.except('product_usage_data_enabled')
      setting.update_columns(service_ping_settings: service_ping_settings, updated_at: Time.current)
    end
  end

  def down; end
end

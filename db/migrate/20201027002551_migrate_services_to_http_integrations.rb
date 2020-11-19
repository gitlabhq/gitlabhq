# frozen_string_literal: true

class MigrateServicesToHttpIntegrations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  ALERT_SERVICE_TYPE = 'AlertsService'
  SERVICE_NAMES_IDENTIFIER = {
    name: 'HTTP endpoint',
    identifier: 'legacy'
  }

  class HttpIntegration < ActiveRecord::Base
    self.table_name = 'alert_management_http_integrations'
  end

  # For each Alerts service,
  # Create the matching HttpIntegration
  def up
    HttpIntegration.reset_column_information

    sql = <<~SQL
      SELECT * FROM services
      JOIN alerts_service_data
      ON (services.id = alerts_service_data.service_id)
      WHERE type = '#{ALERT_SERVICE_TYPE}'
      AND active = TRUE
    SQL

    current_time = Time.current

    values = select_all(sql).map do |alerts_service|
      {
        project_id: alerts_service['project_id'],
        name: SERVICE_NAMES_IDENTIFIER[:name],
        endpoint_identifier: SERVICE_NAMES_IDENTIFIER[:identifier],
        encrypted_token: alerts_service['encrypted_token'],
        encrypted_token_iv: alerts_service['encrypted_token_iv'],
        active: alerts_service['active'],
        updated_at: current_time,
        created_at: current_time
      }
    end

    HttpIntegration.insert_all(values) if values.present?
  end

  def down
    # no-op
  end
end

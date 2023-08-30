# frozen_string_literal: true

# Migrate Integrations::Prometheus records to 'alert_management_http_integrations',
# corresponding to Metrics Dashboard removal in 16.0.
# See https://gitlab.com/gitlab-org/gitlab/-/issues/338838 for more details.
class BackfillAlertManagementPrometheusIntegrations < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 10

  def up
    each_batch_range(:project_alerting_settings, of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        INSERT INTO alert_management_http_integrations (
          project_id,
          encrypted_token,
          encrypted_token_iv,
          active,
          name,
          endpoint_identifier,
          type_identifier,
          created_at,
          updated_at
        ) SELECT
          project_alerting_settings.project_id,
          project_alerting_settings.encrypted_token,
          project_alerting_settings.encrypted_token_iv,
          COALESCE(integrations.active, FALSE),
          'Prometheus',
          'legacy-prometheus',
          1, --type_identifiers { http: 0, prometheus: 1 }
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        FROM project_alerting_settings
        LEFT JOIN integrations
        ON project_alerting_settings.project_id = integrations.project_id
        AND integrations.type_new = 'Integrations::Prometheus'
        WHERE project_alerting_settings.project_id BETWEEN #{min} AND #{max}
        ON CONFLICT DO NOTHING
      SQL
    end
  end

  def down
    execute <<~SQL
      DELETE FROM alert_management_http_integrations
      WHERE type_identifier = 1 --type_identifiers { http: 0, prometheus: 1 }
      AND endpoint_identifier = 'legacy-prometheus'
    SQL
  end
end

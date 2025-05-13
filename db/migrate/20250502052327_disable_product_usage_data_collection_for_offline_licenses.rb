# frozen_string_literal: true

class DisableProductUsageDataCollectionForOfflineLicenses < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.ee?

    # for offline license we disable regardless other settings
    if License.current&.offline_cloud_license?
      execute <<~SQL
        UPDATE application_settings
        SET service_ping_settings =
          COALESCE(service_ping_settings, '{}'::jsonb) ||
          jsonb_build_object('gitlab_product_usage_data_enabled', false)
      SQL
    else
      # When operational metric is required in license, do not opt-out of product usage data
      return if ::License.current&.customer_service_enabled?

      # When offline license is false and operational metric is optional,
      # we opt-out of product usage data when usage ping is off
      execute <<~SQL
          UPDATE application_settings
          SET service_ping_settings =
            COALESCE(service_ping_settings, '{}'::jsonb) ||
            jsonb_build_object('gitlab_product_usage_data_enabled', false)
          WHERE usage_ping_enabled = FALSE;
      SQL
    end
  end
end

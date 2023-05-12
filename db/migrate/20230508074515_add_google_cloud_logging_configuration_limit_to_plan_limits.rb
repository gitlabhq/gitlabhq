# frozen_string_literal: true

class AddGoogleCloudLoggingConfigurationLimitToPlanLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column(:plan_limits, :google_cloud_logging_configurations, :integer, default: 5, null: false)
  end
end

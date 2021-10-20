# frozen_string_literal: true

class FixDeprecatedApiThrottleDefaults < Gitlab::Database::Migration[1.0]
  def change
    change_column_default :application_settings, :throttle_unauthenticated_deprecated_api_requests_per_period, from: 3600, to: 1800
    change_column_default :application_settings, :throttle_authenticated_deprecated_api_period_in_seconds, from: 1800, to: 3600
  end
end

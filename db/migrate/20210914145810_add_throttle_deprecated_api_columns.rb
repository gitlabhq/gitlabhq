# frozen_string_literal: true

class AddThrottleDeprecatedApiColumns < Gitlab::Database::Migration[1.0]
  def change
    add_column :application_settings, :throttle_unauthenticated_deprecated_api_requests_per_period, :integer, default: 3600, null: false
    add_column :application_settings, :throttle_unauthenticated_deprecated_api_period_in_seconds, :integer, default: 3600, null: false
    add_column :application_settings, :throttle_unauthenticated_deprecated_api_enabled, :boolean, default: false, null: false

    add_column :application_settings, :throttle_authenticated_deprecated_api_requests_per_period, :integer, default: 3600, null: false
    add_column :application_settings, :throttle_authenticated_deprecated_api_period_in_seconds, :integer, default: 1800, null: false
    add_column :application_settings, :throttle_authenticated_deprecated_api_enabled, :boolean, default: false, null: false
  end
end

# frozen_string_literal: true

class AddThrottleUnauthenticatedApiColumns < ActiveRecord::Migration[6.1]
  def change
    # The defaults match those from the current `throttle_unauthenticated_*` columns
    add_column :application_settings, :throttle_unauthenticated_api_enabled, :boolean, default: false, null: false
    add_column :application_settings, :throttle_unauthenticated_api_requests_per_period, :integer, default: 3600, null: false
    add_column :application_settings, :throttle_unauthenticated_api_period_in_seconds, :integer, default: 3600, null: false
  end
end

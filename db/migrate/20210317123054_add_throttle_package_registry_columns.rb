# frozen_string_literal: true

class AddThrottlePackageRegistryColumns < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :throttle_unauthenticated_packages_api_requests_per_period, :integer, default: 800, null: false
    add_column :application_settings, :throttle_unauthenticated_packages_api_period_in_seconds, :integer, default: 15, null: false
    add_column :application_settings, :throttle_authenticated_packages_api_requests_per_period, :integer, default: 1000, null: false
    add_column :application_settings, :throttle_authenticated_packages_api_period_in_seconds, :integer, default: 15, null: false
    add_column :application_settings, :throttle_unauthenticated_packages_api_enabled, :boolean, default: false, null: false
    add_column :application_settings, :throttle_authenticated_packages_api_enabled, :boolean, default: false, null: false
  end
end

# frozen_string_literal: true

class AddThrottleFilesApiColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :application_settings, :throttle_unauthenticated_files_api_requests_per_period, :integer, default: 125, null: false
    add_column :application_settings, :throttle_unauthenticated_files_api_period_in_seconds, :integer, default: 15, null: false
    add_column :application_settings, :throttle_authenticated_files_api_requests_per_period, :integer, default: 500, null: false
    add_column :application_settings, :throttle_authenticated_files_api_period_in_seconds, :integer, default: 15, null: false

    add_column :application_settings, :throttle_unauthenticated_files_api_enabled, :boolean, default: false, null: false
    add_column :application_settings, :throttle_authenticated_files_api_enabled, :boolean, default: false, null: false
  end
end

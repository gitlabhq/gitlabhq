# frozen_string_literal: true

class AddThrottleProtectedPathColumns < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  DEFAULT_PROTECTED_PATHS = [
    '/users/password',
    '/users/sign_in',
    '/api/v3/session.json',
    '/api/v3/session',
    '/api/v4/session.json',
    '/api/v4/session',
    '/users',
    '/users/confirmation',
    '/unsubscribes/',
    '/import/github/personal_access_token'
  ]

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :application_settings, :throttle_protected_paths_enabled, :boolean, default: true, null: false
    add_column :application_settings, :throttle_protected_paths_requests_per_period, :integer, default: 10, null: false
    add_column :application_settings, :throttle_protected_paths_period_in_seconds, :integer, default: 60, null: false
    add_column :application_settings, :protected_paths, :string, array: true, limit: 255, default: DEFAULT_PROTECTED_PATHS
  end
  # rubocop:enable Migration/PreventStrings
end

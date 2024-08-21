# frozen_string_literal: true

class AddObservabilityBackendSslVerificationEnabledToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  enable_lock_retries!

  def change
    add_column :application_settings, :observability_backend_ssl_verification_enabled, :boolean, null: false,
      default: true
  end
end

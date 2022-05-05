# frozen_string_literal: true

class AddEnforceAuthChecksOnUploadsToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :enforce_auth_checks_on_uploads, :boolean, null: false, default: true
  end
end

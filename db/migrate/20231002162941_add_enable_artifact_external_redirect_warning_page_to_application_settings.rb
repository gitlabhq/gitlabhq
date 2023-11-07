# frozen_string_literal: true

class AddEnableArtifactExternalRedirectWarningPageToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column(:application_settings, :enable_artifact_external_redirect_warning_page, :boolean, default: true,
      null: false)
  end
end

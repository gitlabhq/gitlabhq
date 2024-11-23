# frozen_string_literal: true

class AddCiJobTokenSigningKeyToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :application_settings, :encrypted_ci_job_token_signing_key, :binary
    add_column :application_settings, :encrypted_ci_job_token_signing_key_iv, :binary
  end
end

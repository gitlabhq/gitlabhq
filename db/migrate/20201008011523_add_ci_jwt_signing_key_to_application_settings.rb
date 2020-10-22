# frozen_string_literal: true

class AddCiJwtSigningKeyToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20201001011937_add_text_limit_to_application_settings_encrypted_ci_jwt_signing_key_iv
  def change
    add_column :application_settings, :encrypted_ci_jwt_signing_key, :text
    add_column :application_settings, :encrypted_ci_jwt_signing_key_iv, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

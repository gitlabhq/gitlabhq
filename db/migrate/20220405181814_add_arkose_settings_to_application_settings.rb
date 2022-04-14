# frozen_string_literal: true

class AddArkoseSettingsToApplicationSettings < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220405203843_add_text_limit_to_arkose_verify_url_application_settings.rb
  def up
    add_column :application_settings, :encrypted_arkose_labs_public_api_key, :binary
    add_column :application_settings, :encrypted_arkose_labs_public_api_key_iv, :binary

    add_column :application_settings, :encrypted_arkose_labs_private_api_key, :binary
    add_column :application_settings, :encrypted_arkose_labs_private_api_key_iv, :binary

    add_column :application_settings, :arkose_labs_verify_api_url, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :application_settings, :encrypted_arkose_labs_public_api_key
    remove_column :application_settings, :encrypted_arkose_labs_public_api_key_iv

    remove_column :application_settings, :encrypted_arkose_labs_private_api_key
    remove_column :application_settings, :encrypted_arkose_labs_private_api_key_iv

    remove_column :application_settings, :arkose_labs_verify_api_url
  end
end

# frozen_string_literal: true

class AddContentValidationEndpointToApplicationSettings < Gitlab::Database::Migration[1.0]
  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    add_column :application_settings, :content_validation_endpoint_url, :text, comment: 'JiHu-specific column'
    # rubocop:disable Migration/AddLimitToTextColumns

    add_column :application_settings, :encrypted_content_validation_api_key, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_content_validation_api_key_iv, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :content_validation_endpoint_enabled, :boolean, null: false, default: false, comment: 'JiHu-specific column'
  end

  def down
    remove_column :application_settings, :content_validation_endpoint_url
    remove_column :application_settings, :encrypted_content_validation_api_key
    remove_column :application_settings, :encrypted_content_validation_api_key_iv
    remove_column :application_settings, :content_validation_endpoint_enabled
  end
end

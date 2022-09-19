# frozen_string_literal: true

class AddCubeApiKeyToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    # rubocop:disable Migration/AddLimitToTextColumns
    add_column :application_settings, :cube_api_base_url, :text
    add_column :application_settings, :encrypted_cube_api_key, :binary
    add_column :application_settings, :encrypted_cube_api_key_iv, :binary
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end

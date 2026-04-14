# frozen_string_literal: true

class AddDeviceCodeEnabledToOauthApplications < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    add_column :oauth_applications, :device_code_enabled, :boolean, default: true, null: false
  end

  def down
    remove_column :oauth_applications, :device_code_enabled
  end
end

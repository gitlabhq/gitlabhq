# frozen_string_literal: true

class AddRopcEnabledToOauthApplications < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :oauth_applications, :ropc_enabled, :boolean, default: true, null: false
  end
end

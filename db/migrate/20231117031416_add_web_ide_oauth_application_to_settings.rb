# frozen_string_literal: true

class AddWebIdeOauthApplicationToSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column :application_settings, :web_ide_oauth_application_id, :int, null: true
  end
end

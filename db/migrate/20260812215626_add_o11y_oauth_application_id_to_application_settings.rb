# frozen_string_literal: true

class AddO11yOauthApplicationIdToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :application_settings, :o11y_oauth_application_id, :bigint
  end
end

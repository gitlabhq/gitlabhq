# frozen_string_literal: true

class AddSlackIntegrationsBotColumns < Gitlab::Database::Migration[2.0]
  def change
    change_table :slack_integrations do |t|
      t.column :bot_user_id, :text
      t.column :encrypted_bot_access_token, :binary
      t.column :encrypted_bot_access_token_iv, :binary
    end
  end
end

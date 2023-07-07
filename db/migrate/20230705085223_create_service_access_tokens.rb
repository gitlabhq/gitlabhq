# frozen_string_literal: true

class CreateServiceAccessTokens < Gitlab::Database::Migration[2.1]
  def change
    create_table :service_access_tokens do |t|
      t.timestamps_with_timezone null: false
      t.integer :category, limit: 2, null: false, default: 0
      t.binary :encrypted_token, null: false
      t.binary :encrypted_token_iv, null: false
    end
  end
end

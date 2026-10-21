# frozen_string_literal: true

class CreateImportUserCredentials < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    create_table :import_user_credentials do |t|
      t.bigint :user_id, null: false
      t.bigint :provider_account_xid, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :expires_at
      t.datetime_with_timezone :refresh_token_expires_at
      t.integer :provider, limit: 2, null: false
      t.jsonb :access_token, null: false
      t.jsonb :refresh_token
      t.text :provider_host, null: false, limit: 255
      t.text :scopes, limit: 255

      t.index [:user_id, :provider, :provider_host, :provider_account_xid], unique: true,
        name: 'idx_import_user_credentials_on_user_provider_host_account'
    end
  end
end

# frozen_string_literal: true

class CreateOauthAccessTokenArchivedRecords < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  # rubocop:disable Migration/PreventStrings -- Keeps compatibility with existing table
  # rubocop:disable Migration/Datetime -- Keeps compatibility with existing table
  def up
    create_table :oauth_access_token_archived_records, id: false do |t|
      t.bigint :id, null: false
      t.bigint :resource_owner_id
      t.bigint :application_id
      t.string :token, null: false
      t.string :refresh_token
      t.integer :expires_in, default: 7200, null: false
      t.datetime :revoked_at
      t.datetime :created_at, null: false
      t.string :scopes
      t.references :organization, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :archived_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
    execute "ALTER TABLE oauth_access_token_archived_records ADD PRIMARY KEY (id)"
  end
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/Datetime

  def down
    drop_table :oauth_access_token_archived_records
  end
end

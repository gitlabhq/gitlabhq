# frozen_string_literal: true

class CreateOauthAccessGrantArchivedRecords < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  # rubocop:disable Migration/EnsureFactoryForTable -- No factory needed for temporary table
  # rubocop:disable Migration/AddLimitToTextColumns -- Keeps compatibility with existing table
  # rubocop:disable Migration/PreventStrings -- Keeps compatibility with existing table
  # rubocop:disable Migration/Datetime -- Keeps compatibility with existing table
  def up
    unless table_exists?(:oauth_access_grant_archived_records)
      create_table :oauth_access_grant_archived_records, id: false do |t|
        t.bigint :id, null: false
        t.bigint :resource_owner_id, null: false
        t.bigint :application_id, null: false
        t.string :token, null: false
        t.integer :expires_in, null: false
        t.text :redirect_uri, null: false
        t.datetime :created_at, null: false
        t.datetime :revoked_at
        t.string :scopes
        t.text :code_challenge
        t.text :code_challenge_method
        t.references :organization, null: false, index: true, foreign_key: { on_delete: :cascade }
        t.datetime_with_timezone :archived_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      end

      execute "ALTER TABLE oauth_access_grant_archived_records ADD PRIMARY KEY (id)"
    end

    add_text_limit :oauth_access_grant_archived_records, :code_challenge, 128
    add_text_limit :oauth_access_grant_archived_records, :code_challenge_method, 5
  end

  # rubocop:enable Migration/EnsureFactoryForTable
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/Datetime

  def down
    drop_table :oauth_access_grant_archived_records, if_exists: true
  end
end

# frozen_string_literal: true

class DropOauthAccessGrantArchivedRecords < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = :oauth_access_grant_archived_records

  def up
    drop_table(TABLE_NAME, if_exists: true)
  end

  # rubocop:disable Migration/Datetime -- Keeps compatibility with existing table
  def down
    unless table_exists?(TABLE_NAME)
      create_table TABLE_NAME, id: false do |t|
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

    add_text_limit TABLE_NAME, :code_challenge, 128
    add_text_limit TABLE_NAME, :code_challenge_method, 5
  end

  # rubocop:enable Migration/Datetime
end

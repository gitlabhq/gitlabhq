# frozen_string_literal: true

class CreateAtlassianIdentities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:atlassian_identities)
      with_lock_retries do
        create_table :atlassian_identities, id: false do |t|
          t.references :user, index: false, foreign_key: { on_delete: :cascade }, null: false, primary_key: true
          t.timestamps_with_timezone
          t.datetime_with_timezone :expires_at
          t.text :extern_uid, null: false, index: { unique: true }
          t.binary :encrypted_token
          t.binary :encrypted_token_iv
          t.binary :encrypted_refresh_token
          t.binary :encrypted_refresh_token_iv
        end
      end
    end

    add_text_limit :atlassian_identities, :extern_uid, 255

    add_check_constraint :atlassian_identities, 'octet_length(encrypted_token) <= 2048', 'atlassian_identities_token_length_constraint'
    add_check_constraint :atlassian_identities, 'octet_length(encrypted_token_iv) <= 12', 'atlassian_identities_token_iv_length_constraint'
    add_check_constraint :atlassian_identities, 'octet_length(encrypted_refresh_token) <= 512', 'atlassian_identities_refresh_token_length_constraint'
    add_check_constraint :atlassian_identities, 'octet_length(encrypted_refresh_token_iv) <= 12', 'atlassian_identities_refresh_token_iv_length_constraint'
  end

  def down
    with_lock_retries do
      drop_table :atlassian_identities
    end
  end
end

# frozen_string_literal: true

class CreateOauthConsents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    create_table :oauth_consents, if_not_exists: true do |t|
      t.bigint :user_id, null: false
      t.timestamps_with_timezone null: false
      t.column :status, :smallint, null: false, default: 0
      # rubocop:disable Migration/AddLimitToTextColumns -- no limit to be consistent with oauth_applications.uid
      t.text :client_id, null: false
      # rubocop:enable Migration/AddLimitToTextColumns
      t.text :consent_challenge, null: false
      t.column :requested_scopes, :text, array: true
      t.column :granted_scopes, :text, array: true
    end

    add_text_limit :oauth_consents, :consent_challenge, 100

    add_check_constraint :oauth_consents,
      'CARDINALITY(requested_scopes) <= 50',
      'check_oauth_consents_requested_scopes_size'
    add_check_constraint :oauth_consents,
      'CARDINALITY(granted_scopes) <= 50',
      'check_oauth_consents_granted_scopes_size'

    add_index :oauth_consents, :consent_challenge, unique: true
    add_index :oauth_consents, :client_id
    add_index :oauth_consents, [:user_id, :status]
  end

  def down
    drop_table :oauth_consents
  end
end

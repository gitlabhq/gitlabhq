# frozen_string_literal: true

class CreateOauthConsentGrantGranularScopes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  UNIQUE_INDEX_NAME = 'idx_oauth_consent_grant_granular_scopes_on_grant_id_scope_id'

  def up
    create_table :oauth_consent_grant_granular_scopes, if_not_exists: true do |t|
      t.references :oauth_consent_grant, null: false, index: false
      t.references :granular_scope, null: false, index: true
      t.references :organization, null: false, index: true

      t.index [:oauth_consent_grant_id, :granular_scope_id], unique: true, name: UNIQUE_INDEX_NAME
    end

    add_concurrent_foreign_key :oauth_consent_grant_granular_scopes, :oauth_consent_grants,
      column: :oauth_consent_grant_id, on_delete: :cascade
    add_concurrent_foreign_key :oauth_consent_grant_granular_scopes, :granular_scopes,
      column: :granular_scope_id, on_delete: :cascade
    add_concurrent_foreign_key :oauth_consent_grant_granular_scopes, :organizations,
      column: :organization_id, on_delete: :cascade
  end

  def down
    drop_table :oauth_consent_grant_granular_scopes
  end
end

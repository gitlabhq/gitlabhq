# frozen_string_literal: true

class CreateOauthApplicationGranularScopes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  UNIQUE_INDEX_NAME = 'idx_oauth_application_granular_scopes_on_app_id_scope_id'

  def up
    create_table :oauth_application_granular_scopes, if_not_exists: true do |t|
      t.references :application, null: false, index: false
      t.references :granular_scope, null: false, index: true
      t.references :organization, null: false, index: true

      t.index [:application_id, :granular_scope_id], unique: true, name: UNIQUE_INDEX_NAME
    end

    # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- applications are destroyed outside their destroy service too; the cascade is recorded in spec/support/database/destroy_service_foreign_keys_todo.yml
    add_concurrent_foreign_key :oauth_application_granular_scopes, :oauth_applications,
      column: :application_id, on_delete: :cascade
    # rubocop:enable Migration/ForeignKeysToDestroyServiceTables
    add_concurrent_foreign_key :oauth_application_granular_scopes, :granular_scopes,
      column: :granular_scope_id, on_delete: :cascade
    add_concurrent_foreign_key :oauth_application_granular_scopes, :organizations,
      column: :organization_id, on_delete: :cascade
  end

  def down
    drop_table :oauth_application_granular_scopes
  end
end

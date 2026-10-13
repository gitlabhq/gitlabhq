# frozen_string_literal: true

class CreateOauthConsentGrants < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  AUTHORIZED_STATUS = 0
  DUO_SESSION_SOURCE = 3
  ACTIVE_GRANT_INDEX_NAME = 'idx_oauth_consent_grants_on_user_id_and_application_id_active'

  def up
    create_table :oauth_consent_grants, if_not_exists: true do |t|
      t.references :user, null: false, index: true
      t.references :application, null: false, index: true
      t.references :organization, null: false, index: true
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false, default: AUTHORIZED_STATUS
      t.integer :source, limit: 2, null: false

      t.index [:user_id, :application_id], unique: true, name: ACTIVE_GRANT_INDEX_NAME,
        where: "status = #{AUTHORIZED_STATUS} AND source <> #{DUO_SESSION_SOURCE}"
    end

    # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- Users::DestroyService declares handles_removal_of :oauth_consent_grants; the oauth_applications cascade is recorded in spec/support/database/destroy_service_foreign_keys_todo.yml
    add_concurrent_foreign_key :oauth_consent_grants, :users, column: :user_id, on_delete: :cascade
    add_concurrent_foreign_key :oauth_consent_grants, :oauth_applications, column: :application_id, on_delete: :cascade
    # rubocop:enable Migration/ForeignKeysToDestroyServiceTables
    add_concurrent_foreign_key :oauth_consent_grants, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    drop_table :oauth_consent_grants
  end
end

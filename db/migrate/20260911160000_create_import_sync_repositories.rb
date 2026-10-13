# frozen_string_literal: true

class CreateImportSyncRepositories < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  PROVIDER_INSTALLATION_INDEX_NAME = 'index_import_sync_repositories_on_provider_installation_xid'

  def change
    create_table :import_sync_repositories do |t|
      t.references :project, null: false, index: { unique: true }
      t.references :connected_by_user, null: true, foreign_key: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :cutover_requested_at
      t.datetime_with_timezone :cutover_completed_at
      t.bigint :provider_installation_xid, null: false
      t.bigint :provider_account_xid, null: false
      t.bigint :provider_repository_xid, null: false
      t.bigint :application_generation, null: false, default: 0
      t.integer :authority_state, limit: 2, null: false, default: 0
      t.integer :disconnect_reason, limit: 2
      t.integer :restore_authority_state, limit: 2
      t.integer :provider, limit: 2, null: false, default: 0
      t.text :provider_account_login, null: false, limit: 255
      t.text :provider_repository_node_id, null: false, limit: 255
      t.text :provider_full_name, null: false, limit: 255
      t.text :provider_default_branch, limit: 255

      t.index :provider_installation_xid, name: PROVIDER_INSTALLATION_INDEX_NAME
      t.index :provider_repository_xid
      t.check_constraint 'provider = 0', name: 'chk_import_sync_repositories_provider'
      t.check_constraint 'authority_state BETWEEN 0 AND 6', name: 'chk_import_sync_repositories_authority_state'
      t.check_constraint 'disconnect_reason IS NULL OR disconnect_reason BETWEEN 0 AND 3',
        name: 'chk_import_sync_repositories_disconnect_reason'
      t.check_constraint 'restore_authority_state IS NULL OR restore_authority_state IN (0, 2)',
        name: 'chk_import_sync_repositories_restore_authority'
      t.check_constraint 'application_generation >= 0', name: 'chk_import_sync_repositories_application_gen'
      t.check_constraint 'provider_installation_xid > 0', name: 'chk_import_sync_repositories_installation_xid'
      t.check_constraint 'provider_account_xid > 0', name: 'chk_import_sync_repositories_account_xid'
      t.check_constraint 'provider_repository_xid > 0', name: 'chk_import_sync_repositories_provider_repo_xid'
    end
  end
end

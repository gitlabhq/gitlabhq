# frozen_string_literal: true

class CreateImportSyncRepositoryStates < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  UNIQUE_DOMAIN_INDEX_NAME = 'idx_import_sync_repository_states_on_repository_and_domain'

  def change
    create_table :import_sync_repository_states do |t|
      t.references :project, null: false
      # No index here: UNIQUE_DOMAIN_INDEX_NAME below has import_sync_repository_id as its
      # leading column, which already covers lookups and the foreign-key index requirement.
      t.references :import_sync_repository, null: false, index: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :bootstrap_started_at
      t.datetime_with_timezone :last_event_at
      t.datetime_with_timezone :last_sync_started_at
      t.datetime_with_timezone :last_successful_sync_at
      t.bigint :desired_generation, null: false, default: 0
      t.bigint :synced_generation, null: false, default: 0
      t.integer :domain, limit: 2, null: false
      t.integer :state, limit: 2, null: false, default: 0
      t.text :cursor, limit: 2048
      t.text :last_error_code, limit: 255
      t.text :last_error_message, limit: 1024

      t.index [:import_sync_repository_id, :domain], unique: true, name: UNIQUE_DOMAIN_INDEX_NAME
      t.check_constraint 'domain BETWEEN 0 AND 2', name: 'chk_import_sync_repository_states_domain'
      t.check_constraint 'state BETWEEN 0 AND 6', name: 'chk_import_sync_repository_states_state'
      t.check_constraint 'desired_generation >= 0', name: 'chk_import_sync_repository_states_desired_gen'
      t.check_constraint 'synced_generation >= 0', name: 'chk_import_sync_repository_states_synced_gen'
      t.check_constraint 'synced_generation <= desired_generation',
        name: 'chk_import_sync_repository_states_generation_order'
    end
  end
end

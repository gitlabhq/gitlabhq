# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenCacheRemoteEntryStates < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  VERIFICATION_STATE_INDEX_NAME = "idx_vreg_mvn_cache_remote_entry_states_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "idx_vreg_mvn_cache_remote_entry_states_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "idx_vreg_mvn_cache_remote_entry_states_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "idx_vreg_mvn_cache_remote_entry_states_needs_verification"
  VERIFICATION_STARTED_INDEX_NAME = "idx_vreg_mvn_cache_remote_entry_states_on_verification_started"
  FOREIGN_KEY_INDEX_NAME = "idx_vreg_mvn_cache_remote_entry_states_on_entry_iid"
  SHARDING_KEY_INDEX_NAME = "idx_vreg_mvn_cache_remote_entry_states_on_group_id"

  def up
    create_table :virtual_registries_packages_maven_cache_remote_entry_states do |t| # rubocop:disable Migration/EnsureFactoryForTable,Lint/RedundantCopDisableDirective -- TBA in followup MR
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.bigint :virtual_registries_packages_maven_cache_remote_entry_iid, null: false
      t.references :group,
        null: false,
        index: { name: SHARDING_KEY_INDEX_NAME },
        foreign_key: { to_table: :namespaces }
      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2, null: false
      t.binary :verification_checksum, using: 'verification_checksum::bytea'
      t.text :verification_failure, limit: 255

      t.index :virtual_registries_packages_maven_cache_remote_entry_iid,
        name: FOREIGN_KEY_INDEX_NAME,
        unique: true
      t.index :verification_state, name: VERIFICATION_STATE_INDEX_NAME
      t.index :verified_at,
        where: "(verification_state = 0)",
        order: { verified_at: 'ASC NULLS FIRST' },
        name: PENDING_VERIFICATION_INDEX_NAME
      t.index :verification_retry_at,
        where: "(verification_state = 3)",
        order: { verification_retry_at: 'ASC NULLS FIRST' },
        name: FAILED_VERIFICATION_INDEX_NAME
      t.index [:virtual_registries_packages_maven_cache_remote_entry_iid, :verification_started_at],
        where: "(verification_state = 1)",
        name: VERIFICATION_STARTED_INDEX_NAME
      t.index :virtual_registries_packages_maven_cache_remote_entry_iid,
        where: "((verification_state = 0) OR (verification_state = 3))",
        name: NEEDS_VERIFICATION_INDEX_NAME
    end
  end

  def down
    drop_table :virtual_registries_packages_maven_cache_remote_entry_states
  end
end

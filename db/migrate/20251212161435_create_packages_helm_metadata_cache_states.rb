# frozen_string_literal: true

class CreatePackagesHelmMetadataCacheStates < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  VERIFICATION_STATE_INDEX_NAME = "idx_packages_helm_metadata_cache_states_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "idx_packages_helm_metadata_cache_states_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "idx_packages_helm_metadata_cache_states_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "idx_packages_helm_metadata_cache_states_needs_verification_id"
  VERIFICATION_STARTED_INDEX_NAME = "idx_packages_helm_metadata_cache_states_on_verification_started"
  FOREIGN_KEY_INDEX_NAME = "idx_pkgs_helm_metadata_cache_states_on_helm_metadata_cache_id"

  def up
    create_table :packages_helm_metadata_cache_states do |t| # rubocop:disable Migration/EnsureFactoryForTable,Lint/RedundantCopDisableDirective -- TBA in followup MR
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.references :packages_helm_metadata_cache,
        null: false,
        index: { unique: true, name: FOREIGN_KEY_INDEX_NAME },
        foreign_key: { on_delete: :cascade }
      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2, null: false
      t.binary :verification_checksum, using: 'verification_checksum::bytea'
      t.text :verification_failure, limit: 255

      t.index :verification_state, name: VERIFICATION_STATE_INDEX_NAME
      t.index :verified_at,
        where: "(verification_state = 0)",
        order: { verified_at: 'ASC NULLS FIRST' },
        name: PENDING_VERIFICATION_INDEX_NAME
      t.index :verification_retry_at,
        where: "(verification_state = 3)",
        order: { verification_retry_at: 'ASC NULLS FIRST' },
        name: FAILED_VERIFICATION_INDEX_NAME
      t.index [:packages_helm_metadata_cache_id, :verification_started_at],
        where: "(verification_state = 1)",
        name: VERIFICATION_STARTED_INDEX_NAME
      t.index :packages_helm_metadata_cache_id,
        where: "((verification_state = 0) OR (verification_state = 3))",
        name: NEEDS_VERIFICATION_INDEX_NAME
    end
  end

  def down
    drop_table :packages_helm_metadata_cache_states
  end
end

# frozen_string_literal: true

class CreateDependencyProxyManifestStates < Gitlab::Database::Migration[2.0]
  DEPENDENCY_PROXY_MANIFEST_INDEX_NAME = "index_manifest_states_on_dependency_proxy_manifest_id"
  VERIFICATION_STATE_INDEX_NAME = "index_manifest_states_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "index_manifest_states_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "index_manifest_states_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "index_manifest_states_needs_verification"

  enable_lock_retries!

  def up
    create_table :dependency_proxy_manifest_states, id: false do |t|
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.references :dependency_proxy_manifest,
        primary_key: true,
        index: { name: DEPENDENCY_PROXY_MANIFEST_INDEX_NAME },
        default: nil,
        foreign_key: { on_delete: :cascade }
      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, limit: 2, default: 0, null: false
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
      t.index :verification_state,
        where: "(verification_state = 0 OR verification_state = 3)",
        name: NEEDS_VERIFICATION_INDEX_NAME
    end
  end

  def down
    drop_table :dependency_proxy_manifest_states
  end
end

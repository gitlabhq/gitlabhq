# frozen_string_literal: true

class CreatePackagesNugetSymbolStates < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  VERIFICATION_STATE_INDEX_NAME = 'index_packages_nuget_symbol_states_on_verification_state'
  PENDING_VERIFICATION_INDEX_NAME = 'index_packages_nuget_symbol_states_pending_verification'
  FAILED_VERIFICATION_INDEX_NAME = 'index_packages_nuget_symbol_states_failed_verification'
  NEEDS_VERIFICATION_INDEX_NAME = 'index_packages_nuget_symbol_states_needs_verification'

  def up
    create_table :packages_nuget_symbol_states do |t| # rubocop:disable Migration/EnsureFactoryForTable, Lint/RedundantCopDisableDirective -- Will be added with the model in a subsequent MR
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.bigint :packages_nuget_symbol_id, null: false, index: { unique: true }
      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2, null: false
      t.binary :verification_checksum, using: 'verification_checksum::bytea'
      t.text :verification_failure, limit: 255

      t.index :verification_state, name: VERIFICATION_STATE_INDEX_NAME
      t.index :verified_at,
        where: '(verification_state = 0)',
        order: { verified_at: 'ASC NULLS FIRST' },
        name: PENDING_VERIFICATION_INDEX_NAME
      t.index :verification_retry_at,
        where: '(verification_state = 3)',
        order: { verification_retry_at: 'ASC NULLS FIRST' },
        name: FAILED_VERIFICATION_INDEX_NAME
      t.index :verification_state,
        where: '(verification_state = 0 OR verification_state = 3)',
        name: NEEDS_VERIFICATION_INDEX_NAME
    end
  end

  def down
    drop_table :packages_nuget_symbol_states
  end
end

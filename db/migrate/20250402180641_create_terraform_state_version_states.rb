# frozen_string_literal: true

class CreateTerraformStateVersionStates < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    create_table :terraform_state_version_states do |t| # rubocop:disable Migration/EnsureFactoryForTable -- False positive
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.bigint :terraform_state_version_id, null: false
      t.bigint :project_id, null: false

      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2, null: false

      t.binary :verification_checksum, using: 'verification_checksum::bytea'
      t.text :verification_failure, limit: 255

      t.index :project_id
      t.index :terraform_state_version_id, unique: true, name: 'index_terraform_state_version_states_state_version_id'
      t.index :verification_state, name: 'index_terraform_state_version_states_on_verification_state'
      t.index :verified_at,
        where: "(verification_state = 0)",
        order: { verified_at: 'ASC NULLS FIRST' },
        name: 'index_terraform_state_version_states_pending_verification'
      t.index :verification_retry_at,
        where: "(verification_state = 3)",
        order: { verification_retry_at: 'ASC NULLS FIRST' },
        name: 'index_terraform_state_version_states_failed_verification'
      t.index [:terraform_state_version_id, :verification_started_at],
        where: "(verification_state = 1)",
        name: 'index_terraform_state_version_states_on_verification_started'
      t.index :terraform_state_version_id,
        where: "(verification_state = 0 OR verification_state = 3)",
        name: 'index_terraform_state_version_states_needs_verification_tsv_id'
    end
  end
end

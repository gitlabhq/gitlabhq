# frozen_string_literal: true

class CreateSnippetRepositoryStates < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table :snippet_repository_states do |t|
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.bigint :snippet_repository_id, null: false

      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2

      t.binary :verification_checksum, using: 'verification_checksum::bytea'
      t.text :verification_failure, limit: 255

      t.index :snippet_repository_id, unique: true
      t.index :verification_state, name: 'index_snippet_repository_states_on_verification_state'
      t.index :verified_at,
        where: "(verification_state = 0)",
        order: { verified_at: 'ASC NULLS FIRST' },
        name: 'index_snippet_repository_states_pending_verification'
      t.index :verification_retry_at,
        where: "(verification_state = 3)",
        order: { verification_retry_at: 'ASC NULLS FIRST' },
        name: 'index_snippet_repository_states_failed_verification'
      t.index :verification_state,
        where: "(verification_state = 0 OR verification_state = 3)",
        name: 'index_snippet_repository_states_needs_verification'
    end
  end
end

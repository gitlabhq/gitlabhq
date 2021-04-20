# frozen_string_literal: true

class AddVerificationIndexesToSnippetRepositories < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  VERIFICATION_STATE_INDEX_NAME = "index_snippet_repositories_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "index_snippet_repositories_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "index_snippet_repositories_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "index_snippet_repositories_needs_verification"

  disable_ddl_transaction!

  def up
    add_concurrent_index :snippet_repositories, :verification_state, name: VERIFICATION_STATE_INDEX_NAME
    add_concurrent_index :snippet_repositories, :verified_at, where: "(verification_state = 0)", order: { verified_at: 'ASC NULLS FIRST' }, name: PENDING_VERIFICATION_INDEX_NAME
    add_concurrent_index :snippet_repositories, :verification_retry_at, where: "(verification_state = 3)", order: { verification_retry_at: 'ASC NULLS FIRST' }, name: FAILED_VERIFICATION_INDEX_NAME
    add_concurrent_index :snippet_repositories, :verification_state, where: "(verification_state = 0 OR verification_state = 3)", name: NEEDS_VERIFICATION_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :snippet_repositories, VERIFICATION_STATE_INDEX_NAME
    remove_concurrent_index_by_name :snippet_repositories, PENDING_VERIFICATION_INDEX_NAME
    remove_concurrent_index_by_name :snippet_repositories, FAILED_VERIFICATION_INDEX_NAME
    remove_concurrent_index_by_name :snippet_repositories, NEEDS_VERIFICATION_INDEX_NAME
  end
end

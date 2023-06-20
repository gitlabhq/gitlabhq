# frozen_string_literal: true

class DropProjectWikiRepositoryStates < Gitlab::Database::Migration[2.1]
  VERIFICATION_STATE_INDEX_NAME = "index_project_wiki_repository_states_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "index_project_wiki_repository_states_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "index_project_wiki_repository_states_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "index_project_wiki_repository_states_needs_verification"
  PROJECT_WIKI_REPOSITORY_INDEX_NAME = "idx_project_wiki_repository_states_project_wiki_repository_id"

  disable_ddl_transaction!

  def up
    drop_table :project_wiki_repository_states, if_exists: true
  end

  def down
    unless table_exists?(:project_wiki_repository_states)
      create_table :project_wiki_repository_states, id: false do |t| # rubocop:disable Migration/SchemaAdditionMethodsNoPost
        t.datetime_with_timezone :verification_started_at
        t.datetime_with_timezone :verification_retry_at
        t.datetime_with_timezone :verified_at
        t.bigint :project_id, primary_key: true, index: false
        t.integer :verification_state, default: 0, limit: 2, null: false
        t.integer :verification_retry_count, limit: 2
        t.binary :verification_checksum, using: 'verification_checksum::bytea'
        t.text :verification_failure, limit: 255
        t.bigint :project_wiki_repository_id

        t.index :verification_state,
          name: VERIFICATION_STATE_INDEX_NAME

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

    add_concurrent_index :project_wiki_repository_states,
      :project_wiki_repository_id,
      name: PROJECT_WIKI_REPOSITORY_INDEX_NAME

    add_concurrent_foreign_key :project_wiki_repository_states,
      :project_wiki_repositories,
      column: :project_wiki_repository_id,
      on_delete: :cascade
  end
end

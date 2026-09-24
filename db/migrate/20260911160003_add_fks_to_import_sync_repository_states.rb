# frozen_string_literal: true

class AddFksToImportSyncRepositoryStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  def up
    add_concurrent_foreign_key :import_sync_repository_states, :projects,
      column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :import_sync_repository_states, :import_sync_repositories,
      column: :import_sync_repository_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :import_sync_repository_states, column: :import_sync_repository_id
      remove_foreign_key_if_exists :import_sync_repository_states, column: :project_id
    end
  end
end

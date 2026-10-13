# frozen_string_literal: true

class AddFksToImportSyncRepositories < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  def up
    # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- cascade/nullify at DB level, no application callbacks needed
    add_concurrent_foreign_key :import_sync_repositories, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :import_sync_repositories, :users, column: :connected_by_user_id, on_delete: :nullify
    # rubocop:enable Migration/ForeignKeysToDestroyServiceTables
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :import_sync_repositories, column: :connected_by_user_id
      remove_foreign_key_if_exists :import_sync_repositories, column: :project_id
    end
  end
end

# frozen_string_literal: true

class AddFksToImportSyncExternalObjects < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  def up
    add_concurrent_foreign_key :import_sync_external_objects, :projects,
      column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :import_sync_external_objects, :import_sync_repositories,
      column: :import_sync_repository_id, on_delete: :cascade
    # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- cascade at DB level, no application callbacks needed
    add_concurrent_foreign_key :import_sync_external_objects, :issues, column: :issue_id, on_delete: :cascade
    add_concurrent_foreign_key :import_sync_external_objects, :merge_requests,
      column: :merge_request_id, on_delete: :cascade
    add_concurrent_foreign_key :import_sync_external_objects, :notes, column: :note_id, on_delete: :cascade
    # rubocop:enable Migration/ForeignKeysToDestroyServiceTables
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :import_sync_external_objects, column: :note_id
      remove_foreign_key_if_exists :import_sync_external_objects, column: :merge_request_id
      remove_foreign_key_if_exists :import_sync_external_objects, column: :issue_id
      remove_foreign_key_if_exists :import_sync_external_objects, column: :import_sync_repository_id
      remove_foreign_key_if_exists :import_sync_external_objects, column: :project_id
    end
  end
end

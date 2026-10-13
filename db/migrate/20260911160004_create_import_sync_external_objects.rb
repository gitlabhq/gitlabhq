# frozen_string_literal: true

class CreateImportSyncExternalObjects < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  UNIQUE_PROVIDER_OBJECT_INDEX_NAME = 'idx_import_sync_external_objects_on_repository_kind_provider'
  UNIQUE_ISSUE_INDEX_NAME = 'idx_import_sync_external_objects_on_issue_id'
  UNIQUE_MERGE_REQUEST_INDEX_NAME = 'idx_import_sync_external_objects_on_merge_request_id'
  UNIQUE_NOTE_INDEX_NAME = 'idx_import_sync_external_objects_on_note_id'
  EXACTLY_ONE_LOCAL_RECORD_CONSTRAINT = 'chk_import_sync_external_objects_one_local_record'

  def change
    create_table :import_sync_external_objects do |t|
      t.references :project, null: false
      # No index here: the composite UNIQUE_PROVIDER_OBJECT_INDEX_NAME index below has
      # import_sync_repository_id as its leading column, which already covers lookups
      # and satisfies the foreign-key index requirement.
      t.references :import_sync_repository, null: false, index: false
      t.references :issue, null: true, index: false, foreign_key: false
      t.references :merge_request, null: true, index: false, foreign_key: false
      t.references :note, null: true, index: false, foreign_key: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :provider_updated_at
      t.bigint :provider_object_xid, null: false
      t.integer :kind, limit: 2, null: false

      t.index [:import_sync_repository_id, :kind, :provider_object_xid],
        unique: true,
        name: UNIQUE_PROVIDER_OBJECT_INDEX_NAME
      t.index :issue_id, unique: true, where: 'issue_id IS NOT NULL', name: UNIQUE_ISSUE_INDEX_NAME
      t.index :merge_request_id, unique: true, where: 'merge_request_id IS NOT NULL',
        name: UNIQUE_MERGE_REQUEST_INDEX_NAME
      t.index :note_id, unique: true, where: 'note_id IS NOT NULL', name: UNIQUE_NOTE_INDEX_NAME
      t.check_constraint 'kind BETWEEN 0 AND 2', name: 'chk_import_sync_external_objects_kind'
      t.check_constraint 'provider_object_xid > 0', name: 'chk_import_sync_external_objects_provider_xid'
      t.check_constraint 'num_nonnulls(issue_id, merge_request_id, note_id) = 1',
        name: EXACTLY_ONE_LOCAL_RECORD_CONSTRAINT
    end
  end
end

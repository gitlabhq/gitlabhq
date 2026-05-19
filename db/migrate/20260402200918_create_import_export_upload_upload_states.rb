# frozen_string_literal: true

class CreateImportExportUploadUploadStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  UNIQUE_INDEX_NAME = "idx_ie_upload_uploads_on_id"
  VERIFICATION_STATE_INDEX_NAME = "idx_ie_upload_upload_states_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "idx_ie_upload_upload_states_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "idx_ie_upload_upload_states_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "idx_ie_upload_upload_states_needs_verification_id"
  VERIFICATION_STARTED_INDEX_NAME = "idx_ie_upload_upload_states_on_verification_started"

  def up
    add_concurrent_index :import_export_upload_uploads, :id, unique: true, name: UNIQUE_INDEX_NAME,
      allow_partition: true

    create_table :import_export_upload_upload_states, if_not_exists: true do |t|
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.references :import_export_upload_upload,
        null: false,
        index: { unique: true, name: :idx_import_export_upload_upload_states_on_upload_id }
      t.bigint :project_id
      t.bigint :namespace_id
      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2, null: false
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
      t.index [:import_export_upload_upload_id, :verification_started_at],
        where: "(verification_state = 1)",
        name: VERIFICATION_STARTED_INDEX_NAME
      t.index :import_export_upload_upload_id,
        where: "((verification_state = 0) OR (verification_state = 3))",
        name: NEEDS_VERIFICATION_INDEX_NAME
      t.index :project_id
      t.index :namespace_id
    end

    add_concurrent_foreign_key :import_export_upload_upload_states, :import_export_upload_uploads,
      column: :import_export_upload_upload_id, on_delete: :cascade
    add_concurrent_foreign_key :import_export_upload_upload_states, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :import_export_upload_upload_states, :namespaces, column: :namespace_id,
      on_delete: :cascade
    add_multi_column_not_null_constraint(:import_export_upload_upload_states, :project_id, :namespace_id)
  end

  def down
    drop_table :import_export_upload_upload_states
    execute("DROP INDEX IF EXISTS #{UNIQUE_INDEX_NAME}")
  end
end

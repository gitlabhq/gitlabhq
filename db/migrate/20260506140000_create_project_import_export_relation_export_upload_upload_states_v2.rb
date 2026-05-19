# frozen_string_literal: true

class CreateProjectImportExportRelationExportUploadUploadStatesV2 < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  VERIFICATION_STATE_INDEX_NAME = "idx_piere_upload_upload_states_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "idx_piere_upload_upload_states_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "idx_piere_upload_upload_states_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "idx_piere_upload_upload_states_needs_verification_id"
  VERIFICATION_STARTED_INDEX_NAME = "idx_piere_upload_upload_states_on_verification_started"

  def up
    create_table :project_import_export_relation_export_upload_upload_states, if_not_exists: true do |t|
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.references :project_import_export_relation_export_upload_upload,
        null: false,
        index: { unique: true, name: 'idx_piere_upload_upload_states_on_upload_upload_id' }
      t.bigint :project_id, null: false
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
      t.index [:project_import_export_relation_export_upload_upload_id, :verification_started_at],
        where: "(verification_state = 1)",
        name: VERIFICATION_STARTED_INDEX_NAME
      t.index :project_import_export_relation_export_upload_upload_id,
        where: "((verification_state = 0) OR (verification_state = 3))",
        name: NEEDS_VERIFICATION_INDEX_NAME
      t.index :project_id, name: 'idx_piere_upload_upload_states_on_project_id'
    end
  end

  def down
    drop_table :project_import_export_relation_export_upload_upload_states
  end
end

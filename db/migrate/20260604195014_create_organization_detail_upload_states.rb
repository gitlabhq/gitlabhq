# frozen_string_literal: true

class CreateOrganizationDetailUploadStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  VERIFICATION_STATE_INDEX_NAME = "idx_od_upl_states_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "idx_od_upl_states_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "idx_od_upl_states_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "idx_od_upl_states_needs_verification_id"
  VERIFICATION_STARTED_INDEX_NAME = "idx_od_upl_states_on_verification_started"
  REFERENCES_INDEX_NAME = "idx_od_upl_states_on_od_upl_id"

  def up
    create_table :organization_detail_upload_states, if_not_exists: true do |t|
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.references :organization_detail_upload,
        null: false,
        index: { unique: true, name: REFERENCES_INDEX_NAME }
      t.bigint :organization_id, null: false
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
      t.index [:organization_detail_upload_id, :verification_started_at],
        where: "(verification_state = 1)",
        name: VERIFICATION_STARTED_INDEX_NAME
      t.index :organization_detail_upload_id,
        where: "((verification_state = 0) OR (verification_state = 3))",
        name: NEEDS_VERIFICATION_INDEX_NAME
      t.index :organization_id
    end

    add_concurrent_foreign_key :organization_detail_upload_states, :organization_detail_uploads,
      column: :organization_detail_upload_id, on_delete: :cascade
    add_concurrent_foreign_key :organization_detail_upload_states, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    drop_table :organization_detail_upload_states
  end
end

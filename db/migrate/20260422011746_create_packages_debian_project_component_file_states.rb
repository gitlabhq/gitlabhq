# frozen_string_literal: true

class CreatePackagesDebianProjectComponentFileStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  VERIFICATION_STATE_INDEX_NAME = "index_pkg_deb_proj_comp_file_states_on_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "index_pkg_deb_proj_comp_file_states_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "index_pkg_deb_proj_comp_file_states_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "index_pkg_deb_proj_comp_file_states_needs_verification"
  VERIFICATION_STARTED_INDEX_NAME = "index_pkg_deb_proj_comp_file_states_on_verification_started"

  def up
    create_table :packages_debian_project_component_file_states, if_not_exists: true do |t| # rubocop:disable Migration/EnsureFactoryForTable -- Will be added with the model in a subsequent MR
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.bigint :packages_debian_project_component_file_id, null: false,
        index: { unique: true, name: 'index_pkg_deb_proj_comp_file_states_on_fk' }
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
      t.index [:packages_debian_project_component_file_id, :verification_started_at],
        where: "(verification_state = 1)",
        name: VERIFICATION_STARTED_INDEX_NAME
      # Indexed on the file_id column (not verification_state) because the hot query is
      # `where(verification_state: [0, 3]).pluck(:packages_debian_project_component_file_id)`:
      # batch fetching IDs to verify, not counting by state.
      t.index :packages_debian_project_component_file_id,
        where: "((verification_state = 0) OR (verification_state = 3))",
        name: NEEDS_VERIFICATION_INDEX_NAME
      t.index :project_id, name: 'index_pkg_deb_proj_comp_file_states_on_project_id'
    end

    add_concurrent_foreign_key :packages_debian_project_component_file_states, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    drop_table :packages_debian_project_component_file_states
  end
end

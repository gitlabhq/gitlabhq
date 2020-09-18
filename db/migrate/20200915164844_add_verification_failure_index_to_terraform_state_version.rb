# frozen_string_literal: true

class AddVerificationFailureIndexToTerraformStateVersion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  FAILURE_INDEX_NAME = 'terraform_state_versions_verification_failure_partial'
  CHECKSUM_INDEX_NAME = 'terraform_state_versions_verification_checksum_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index :terraform_state_versions, :verification_failure,
                         where: "(verification_failure IS NOT NULL)",
                         name: FAILURE_INDEX_NAME
    add_concurrent_index :terraform_state_versions, :verification_checksum,
                         where: "(verification_checksum IS NOT NULL)",
                         name: CHECKSUM_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :terraform_state_versions, FAILURE_INDEX_NAME
    remove_concurrent_index_by_name :terraform_state_versions, CHECKSUM_INDEX_NAME
  end
end

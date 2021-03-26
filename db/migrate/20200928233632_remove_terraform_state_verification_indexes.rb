# frozen_string_literal: true

class RemoveTerraformStateVerificationIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CHECKSUM_INDEX_NAME = "terraform_states_verification_checksum_partial"
  FAILURE_INDEX_NAME = "terraform_states_verification_failure_partial"

  disable_ddl_transaction!

  def up
    remove_concurrent_index :terraform_states, :verification_failure, name: FAILURE_INDEX_NAME
    remove_concurrent_index :terraform_states, :verification_checksum, name: CHECKSUM_INDEX_NAME
  end

  def down
    add_concurrent_index :terraform_states, :verification_failure, where: "(verification_failure IS NOT NULL)", name: FAILURE_INDEX_NAME
    add_concurrent_index :terraform_states, :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: CHECKSUM_INDEX_NAME
  end
end

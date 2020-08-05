# frozen_string_literal: true

class AddVerificationFailureLimitAndIndexToTerraformStates < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :terraform_states, :verification_failure, where: "(verification_failure IS NOT NULL)", name: "terraform_states_verification_failure_partial"
    add_concurrent_index :terraform_states, :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: "terraform_states_verification_checksum_partial"
    add_text_limit :terraform_states, :verification_failure, 255
  end

  def down
    remove_concurrent_index :terraform_states, :verification_failure
    remove_concurrent_index :terraform_states, :verification_checksum
    remove_text_limit :terraform_states, :verification_failure
  end
end

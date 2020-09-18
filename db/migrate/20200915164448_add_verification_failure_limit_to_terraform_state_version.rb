# frozen_string_literal: true

class AddVerificationFailureLimitToTerraformStateVersion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'tf_state_versions_verification_failure_text_limit'

  def up
    add_text_limit :terraform_state_versions, :verification_failure, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint(:terraform_state_versions, CONSTRAINT_NAME)
  end
end

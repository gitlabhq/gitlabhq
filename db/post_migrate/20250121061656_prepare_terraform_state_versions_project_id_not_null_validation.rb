# frozen_string_literal: true

class PrepareTerraformStateVersionsProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_84142902f6

  def up
    prepare_async_check_constraint_validation :terraform_state_versions, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :terraform_state_versions, name: CONSTRAINT_NAME
  end
end

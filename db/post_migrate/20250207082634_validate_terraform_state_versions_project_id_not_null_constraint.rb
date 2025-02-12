# frozen_string_literal: true

class ValidateTerraformStateVersionsProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    validate_not_null_constraint :terraform_state_versions, :project_id
  end

  def down
    # no-op
  end
end

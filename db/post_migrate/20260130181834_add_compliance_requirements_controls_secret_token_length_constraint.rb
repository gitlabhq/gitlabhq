# frozen_string_literal: true

class AddComplianceRequirementsControlsSecretTokenLengthConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  ENCRYPTED_LIMIT = 240 + 16
  CONSTRAINT_NAME = 'check_compliance_requirements_controls_secret_token_max_length'
  TABLE_NAME = :compliance_requirements_controls

  def up
    add_check_constraint(
      TABLE_NAME,
      "octet_length(encrypted_secret_token) <= #{ENCRYPTED_LIMIT}",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end
end

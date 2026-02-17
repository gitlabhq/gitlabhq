# frozen_string_literal: true

class AddNotNullNotValidConstraintToSecurityFindingsProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  def up
    add_not_null_constraint :security_findings, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :security_findings, :project_id
  end
end

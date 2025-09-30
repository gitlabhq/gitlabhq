# frozen_string_literal: true

class ValidateNotNullConstraintOnJiraConnectInstallations < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  TABLE_NAME = :jira_connect_installations
  COLUMN_NAME = :organization_id
  CONSTRAINT_NAME = :check_dc0d039821

  def up
    validate_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end

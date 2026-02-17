# frozen_string_literal: true

class ValidateUserAgentDetailsOrganizationIdNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    validate_not_null_constraint :user_agent_details, :organization_id
  end

  def down
    # no-op
  end
end

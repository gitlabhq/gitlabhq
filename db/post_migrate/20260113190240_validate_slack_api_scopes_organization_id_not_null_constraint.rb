# frozen_string_literal: true

class ValidateSlackApiScopesOrganizationIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    validate_check_constraint :slack_api_scopes, :check_930d89be0d
  end

  def down
    # no-op
  end
end

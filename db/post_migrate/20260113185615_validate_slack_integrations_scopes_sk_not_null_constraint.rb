# frozen_string_literal: true

class ValidateSlackIntegrationsScopesSkNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    validate_multi_column_not_null_constraint :slack_integrations_scopes,
      :project_id,
      :group_id,
      :organization_id,
      constraint_name: :check_c5ff08a699
  end

  def down
    # no-op
  end
end

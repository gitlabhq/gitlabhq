# frozen_string_literal: true

class IntegrationsValidateMultipleColumnNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  CONSTRAINT_NAME = 'check_2aae034509'

  def up
    validate_multi_column_not_null_constraint :integrations,
      :project_id,
      :group_id,
      :organization_id,
      constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end

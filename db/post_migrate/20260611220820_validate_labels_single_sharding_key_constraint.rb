# frozen_string_literal: true

class ValidateLabelsSingleShardingKeyConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    validate_multi_column_not_null_constraint :labels, :group_id,
      :organization_id,
      :project_id,
      constraint_name: 'check_2d9a8c1bca'
  end

  def down
    # no-op
    # Not recreating a NOT VALID constraint
  end
end

# frozen_string_literal: true

class ValidateProjectRelationExportsProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :project_relation_exports, :project_id
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class ValidateDescriptionVersionsParentNotNullConstraint < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_76c1eb7122'

  milestone '18.1'

  def up
    validate_multi_column_not_null_constraint :description_versions,
      :issue_id,
      :merge_request_id,
      :epic_id,
      constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end

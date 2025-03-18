# frozen_string_literal: true

class ValidateMergeRequestAssigneesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :merge_request_assignees, :project_id
  end

  def down
    # no-op
  end
end

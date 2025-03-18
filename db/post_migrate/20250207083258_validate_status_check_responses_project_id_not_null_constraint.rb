# frozen_string_literal: true

class ValidateStatusCheckResponsesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :status_check_responses, :project_id
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class ValidateMergeRequestReviewersProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :merge_request_reviewers, :project_id, constraint_name: 'check_fb72c99774'
  end

  def down
    # no-op
  end
end

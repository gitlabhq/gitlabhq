# frozen_string_literal: true

class ValidateMergeRequestDiffsProjectIdNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def up
    validate_not_null_constraint :merge_request_diffs, :project_id
  end

  def down; end
end

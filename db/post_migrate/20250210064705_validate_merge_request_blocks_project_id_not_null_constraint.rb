# frozen_string_literal: true

class ValidateMergeRequestBlocksProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :merge_request_blocks, :project_id
  end

  def down
    # no-op
  end
end

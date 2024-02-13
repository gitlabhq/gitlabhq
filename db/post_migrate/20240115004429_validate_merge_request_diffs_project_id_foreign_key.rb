# frozen_string_literal: true

class ValidateMergeRequestDiffsProjectIdForeignKey < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def up
    validate_foreign_key(:merge_request_diffs, :project_id)
  end

  def down
    # no-op
  end
end

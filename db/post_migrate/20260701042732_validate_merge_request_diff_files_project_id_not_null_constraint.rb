# frozen_string_literal: true

class ValidateMergeRequestDiffFilesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_files_99208b8fac
  COLUMN_NAME = :project_id

  def up
    validate_not_null_constraint TABLE_NAME, COLUMN_NAME
  end

  def down
    # no-op
  end
end

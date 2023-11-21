# frozen_string_literal: true

class AddMergeRequestDiffsProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  def up
    add_not_null_constraint :merge_request_diffs, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :merge_request_diffs, :project_id
  end
end

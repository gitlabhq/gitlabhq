# frozen_string_literal: true

class AddNotNullConstraintToMergeRequestDiffDetailsProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  def up
    add_not_null_constraint :merge_request_diff_details, :project_id
  end

  def down
    remove_not_null_constraint :merge_request_diff_details, :project_id
  end
end

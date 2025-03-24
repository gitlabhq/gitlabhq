# frozen_string_literal: true

class AddDescriptionVersionsUniqueParentConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_multi_column_not_null_constraint(:description_versions, :issue_id, :merge_request_id, :epic_id, validate: false)
  end

  def down
    remove_multi_column_not_null_constraint(:description_versions, :issue_id, :merge_request_id, :epic_id)
  end
end

# frozen_string_literal: true

class AddEpicIssuesWorkItemParentLinkIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_not_null_constraint :epic_issues, :work_item_parent_link_id, validate: false
  end

  def down
    remove_not_null_constraint :epic_issues, :work_item_parent_link_id
  end
end

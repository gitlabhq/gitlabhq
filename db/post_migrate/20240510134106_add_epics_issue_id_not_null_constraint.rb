# frozen_string_literal: true

class AddEpicsIssueIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  def up
    add_not_null_constraint :epics, :issue_id, validate: false
  end

  def down
    remove_not_null_constraint :epics, :issue_id
  end
end

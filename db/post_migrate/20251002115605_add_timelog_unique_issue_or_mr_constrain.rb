# frozen_string_literal: true

class AddTimelogUniqueIssueOrMrConstrain < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_multi_column_not_null_constraint(:timelogs, :issue_id, :merge_request_id)
  end

  def down
    remove_multi_column_not_null_constraint(:timelogs, :issue_id, :merge_request_id)
  end
end

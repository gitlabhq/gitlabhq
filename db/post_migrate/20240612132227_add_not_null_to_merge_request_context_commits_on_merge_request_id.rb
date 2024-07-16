# frozen_string_literal: true

class AddNotNullToMergeRequestContextCommitsOnMergeRequestId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.2'

  def up
    add_not_null_constraint :merge_request_context_commits, :merge_request_id
  end

  def down
    remove_not_null_constraint :merge_request_context_commits, :merge_request_id
  end
end

# frozen_string_literal: true

class RemoveDuplicatedApprovalsIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  INDEX_NAME = 'index_approvals_on_merge_request_id'

  def up
    remove_concurrent_index_by_name :approvals, name: INDEX_NAME
  end

  def down
    add_concurrent_index :approvals, :merge_request_id, name: INDEX_NAME
  end
end

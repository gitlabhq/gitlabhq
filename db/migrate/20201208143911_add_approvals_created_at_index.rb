# frozen_string_literal: true

class AddApprovalsCreatedAtIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_approvals_on_merge_request_id_and_created_at'

  def up
    add_concurrent_index :approvals, [:merge_request_id, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approvals, INDEX_NAME
  end
end

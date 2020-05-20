# frozen_string_literal: true

class AddSprintIdIndexToMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, :sprint_id
    add_concurrent_foreign_key :merge_requests, :sprints, column: :sprint_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_requests, column: :sprint_id
    end
    remove_concurrent_index :merge_requests, :sprint_id
  end
end

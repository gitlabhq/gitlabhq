# frozen_string_literal: true

class AddSprintToMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      # index will be added in another migration with `add_concurrent_index`
      add_column :merge_requests, :sprint_id, :bigint
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_requests, :sprint_id
    end
  end
end

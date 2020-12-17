# frozen_string_literal: true

class AddSortedToMergeRequestDiffs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :merge_request_diffs, :sorted, :boolean, null: false, default: false
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_request_diffs, :sorted
    end
  end
end

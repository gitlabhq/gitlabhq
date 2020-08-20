# frozen_string_literal: true

class AddFileCountToMergeRequestDiffs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :merge_request_diffs, :files_count, :smallint
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_request_diffs, :files_count, :smallint
    end
  end
end

# frozen_string_literal: true

class AddDefaultValueForExternalDiffStoreToMergeRequestDiffs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :merge_request_diffs, :external_diff_store, 1
    end
  end

  def down
    with_lock_retries do
      change_column_default :merge_request_diffs, :external_diff_store, nil
    end
  end
end

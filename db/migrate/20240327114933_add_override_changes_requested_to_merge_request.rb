# frozen_string_literal: true

class AddOverrideChangesRequestedToMergeRequest < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.11'

  def change
    add_column :merge_requests, :override_requested_changes, :boolean, default: false, null: false
  end
end

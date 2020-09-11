# frozen_string_literal: true

class AddMergeRefShaToMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :merge_requests, :merge_ref_sha, :binary
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_requests, :merge_ref_sha
    end
  end
end

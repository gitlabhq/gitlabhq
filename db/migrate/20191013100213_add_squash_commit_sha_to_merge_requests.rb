# frozen_string_literal: true

class AddSquashCommitShaToMergeRequests < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :merge_requests, :squash_commit_sha, :binary
  end
end

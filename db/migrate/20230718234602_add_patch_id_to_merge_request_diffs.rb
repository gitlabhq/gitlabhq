# frozen_string_literal: true

class AddPatchIdToMergeRequestDiffs < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :merge_request_diffs, :patch_id_sha, :binary
  end

  def down
    remove_column :merge_request_diffs, :patch_id_sha
  end
end

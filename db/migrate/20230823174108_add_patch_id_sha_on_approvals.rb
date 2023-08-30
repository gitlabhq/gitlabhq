# frozen_string_literal: true

class AddPatchIdShaOnApprovals < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :approvals, :patch_id_sha, :binary
  end

  def down
    remove_column :approvals, :patch_id_sha
  end
end

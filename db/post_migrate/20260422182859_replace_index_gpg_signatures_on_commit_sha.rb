# frozen_string_literal: true

class ReplaceIndexGpgSignaturesOnCommitSha < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  OLD_UNIQUE_INDEX = 'index_gpg_signatures_on_commit_sha'
  COMMIT_SHA_COMPOUND_INDEX = 'index_gpg_signatures_on_commit_sha_and_project_id'

  def up
    add_concurrent_index :gpg_signatures, [:commit_sha, :project_id],
      unique: true, name: COMMIT_SHA_COMPOUND_INDEX
    remove_concurrent_index_by_name :gpg_signatures, OLD_UNIQUE_INDEX
  end

  def down
    add_concurrent_index :gpg_signatures, :commit_sha,
      unique: true, name: OLD_UNIQUE_INDEX
    remove_concurrent_index_by_name :gpg_signatures, COMMIT_SHA_COMPOUND_INDEX
  end
end

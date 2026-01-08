# frozen_string_literal: true

class AddCompositeIndexSshSignaturesOnCommitShaProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  COMMIT_SHA_INDEX = 'index_ssh_signatures_on_commit_sha'
  COMPOUND_INDEX_ON_COMMIT_SHA_PROJECT_ID = 'index_ssh_signatures_on_commit_sha_project_id'

  def up
    add_concurrent_index :ssh_signatures, [:commit_sha, :project_id],
      name: COMPOUND_INDEX_ON_COMMIT_SHA_PROJECT_ID,
      unique: true
    remove_concurrent_index_by_name :ssh_signatures, COMMIT_SHA_INDEX
  end

  def down
    add_concurrent_index :ssh_signatures, :commit_sha, name: COMMIT_SHA_INDEX, unique: true
    remove_concurrent_index_by_name :ssh_signatures, COMPOUND_INDEX_ON_COMMIT_SHA_PROJECT_ID
  end
end

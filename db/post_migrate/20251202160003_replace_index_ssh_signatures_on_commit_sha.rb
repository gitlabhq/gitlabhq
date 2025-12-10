# frozen_string_literal: true

class ReplaceIndexSshSignaturesOnCommitSha < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  OLD_UNIQUE_INDEX = 'index_ssh_signatures_on_commit_sha'
  NEW_COMPOUND_INDEX = 'index_ssh_signatures_on_project_id_and_commit_sha'
  REDUNDANT_INDEX = 'index_ssh_signatures_on_project_id'

  def up
    add_concurrent_index :ssh_signatures, [:project_id, :commit_sha], unique: true, name: NEW_COMPOUND_INDEX
    remove_concurrent_index_by_name :ssh_signatures, OLD_UNIQUE_INDEX
    remove_concurrent_index_by_name :ssh_signatures, REDUNDANT_INDEX
  end

  def down
    add_concurrent_index :ssh_signatures, :commit_sha, unique: true, name: OLD_UNIQUE_INDEX
    add_concurrent_index :ssh_signatures, :project_id, name: REDUNDANT_INDEX
    remove_concurrent_index_by_name :ssh_signatures, NEW_COMPOUND_INDEX
  end
end

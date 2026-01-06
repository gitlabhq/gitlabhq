# frozen_string_literal: true

class ReAddIndexSshSignaturesOnCommitSha < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ssh_signatures_on_commit_sha'

  def up
    add_concurrent_index :ssh_signatures, :commit_sha, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ssh_signatures, INDEX_NAME
  end
end

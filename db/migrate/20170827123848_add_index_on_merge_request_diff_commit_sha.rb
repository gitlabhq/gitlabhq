# rubocop:disable RemoveIndex

class AddIndexOnMergeRequestDiffCommitSha < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_diff_commits, :sha, length: mysql_compatible_index_length
  end

  def down
    remove_index :merge_request_diff_commits, :sha if index_exists? :merge_request_diff_commits, :sha
  end
end

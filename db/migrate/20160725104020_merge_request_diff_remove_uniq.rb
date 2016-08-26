# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestDiffRemoveUniq < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    if index_exists?(:merge_request_diffs, :merge_request_id)
      remove_index :merge_request_diffs, :merge_request_id
    end
  end

  def down
    unless index_exists?(:merge_request_diffs, :merge_request_id)
      add_concurrent_index :merge_request_diffs, :merge_request_id, unique: true
    end
  end
end

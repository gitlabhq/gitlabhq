# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MoveFromDevelopersCanMergeToProtectedBranchesMergeAccess < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # When using the methods "add_concurrent_index" or "add_column_with_default"
  # you must disable the use of transactions as these methods can not run in an
  # existing transaction. When using "add_concurrent_index" make sure that this
  # method is the _only_ method called in the migration, any other changes
  # should go in a separate migration. This ensures that upon failure _only_ the
  # index creation fails and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!

  def up
    execute <<-HEREDOC
      INSERT into protected_branch_merge_access_levels (protected_branch_id, access_level, created_at, updated_at)
        SELECT id, (CASE WHEN developers_can_merge THEN 1 ELSE 0 END), now(), now()
          FROM protected_branches
    HEREDOC
  end

  def down
    execute <<-HEREDOC
      UPDATE protected_branches SET developers_can_merge = TRUE
        WHERE id IN (SELECT protected_branch_id FROM protected_branch_merge_access_levels
                       WHERE access_level = 1);
    HEREDOC
  end
end

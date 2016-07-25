# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MoveFromDevelopersCanMergeToProtectedBranchesMergeAccess < ActiveRecord::Migration
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

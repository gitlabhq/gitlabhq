# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MoveFromDevelopersCanMergeToProtectedBranchesMergeAccess < ActiveRecord::Migration
  DOWNTIME = true
  DOWNTIME_REASON = <<-HEREDOC
    We're creating a `merge_access_level` for each `protected_branch`. If a user creates a `protected_branch` while this
    is running, we might be left with a `protected_branch` _without_ an associated `merge_access_level`. The `protected_branches`
    table must not change while this is running, so downtime is required.

    https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5081#note_13247410
  HEREDOC

  def up
    execute <<-HEREDOC
      INSERT into protected_branch_merge_access_levels (protected_branch_id, access_level, created_at, updated_at)
        SELECT id, (CASE WHEN developers_can_merge THEN 30 ELSE 40 END), now(), now()
          FROM protected_branches
    HEREDOC
  end

  def down
    execute <<-HEREDOC
      UPDATE protected_branches SET developers_can_merge = TRUE
        WHERE id IN (SELECT protected_branch_id FROM protected_branch_merge_access_levels
                       WHERE access_level = 30);
    HEREDOC
  end
end

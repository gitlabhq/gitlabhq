# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveUndeletedGroups < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute <<-EOF.strip_heredoc
    DELETE FROM projects
    WHERE namespace_id IN (
      SELECT id FROM (
        SELECT id
        FROM namespaces
        WHERE deleted_at IS NOT NULL
      ) namespace_ids
    );
    EOF

    if defined?(Gitlab::License)
      # EE adds these columns but we have to make sure this data is cleaned up
      # here before we run the DELETE below. An alternative would be patching
      # this migration in EE but this will only result in a mess and confusing
      # migrations.
      execute <<-EOF.strip_heredoc
      DELETE FROM protected_branch_push_access_levels
      WHERE group_id IN (
        SELECT id FROM (
          SELECT id
          FROM namespaces
          WHERE deleted_at IS NOT NULL
        ) namespace_ids
      );
      EOF

      execute <<-EOF.strip_heredoc
      DELETE FROM protected_branch_merge_access_levels
      WHERE group_id IN (
        SELECT id FROM (
          SELECT id
          FROM namespaces
          WHERE deleted_at IS NOT NULL
        ) namespace_ids
      );
      EOF
    end

    # This removes namespaces that were supposed to be soft deleted but still
    # reside in the database.
    execute "DELETE FROM namespaces WHERE deleted_at IS NOT NULL;"
  end

  def down
    # This is an irreversible migration;
    # If someone is trying to rollback for other reasons, we should not throw an Exception.
    # raise ActiveRecord::IrreversibleMigration
  end
end

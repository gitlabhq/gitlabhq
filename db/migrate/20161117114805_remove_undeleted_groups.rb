# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveUndeletedGroups < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    is_ee = defined?(Gitlab::License)

    if is_ee
      execute <<-EOF.strip_heredoc
      DELETE FROM path_locks
      WHERE project_id IN (
        SELECT project_id
        FROM projects
        WHERE namespace_id IN (#{namespaces_pending_removal})
      );
      EOF

      execute <<-EOF.strip_heredoc
      DELETE FROM remote_mirrors
      WHERE project_id IN (
        SELECT project_id
        FROM projects
        WHERE namespace_id IN (#{namespaces_pending_removal})
      );
      EOF
    end

    execute <<-EOF.strip_heredoc
    DELETE FROM lists
    WHERE label_id IN (
      SELECT id
      FROM labels
      WHERE group_id IN (#{namespaces_pending_removal})
    );
    EOF

    execute <<-EOF.strip_heredoc
    DELETE FROM lists
    WHERE board_id IN (
      SELECT id
      FROM boards
      WHERE project_id IN (
        SELECT project_id
        FROM projects
        WHERE namespace_id IN (#{namespaces_pending_removal})
      )
    );
    EOF

    execute <<-EOF.strip_heredoc
    DELETE FROM labels
    WHERE group_id IN (#{namespaces_pending_removal});
    EOF

    execute <<-EOF.strip_heredoc
    DELETE FROM boards
    WHERE project_id IN (
      SELECT project_id
      FROM projects
      WHERE namespace_id IN (#{namespaces_pending_removal})
    )
    EOF

    execute <<-EOF.strip_heredoc
    DELETE FROM projects
    WHERE namespace_id IN (#{namespaces_pending_removal});
    EOF

    if is_ee
      # EE adds these columns but we have to make sure this data is cleaned up
      # here before we run the DELETE below. An alternative would be patching
      # this migration in EE but this will only result in a mess and confusing
      # migrations.
      execute <<-EOF.strip_heredoc
      DELETE FROM protected_branch_push_access_levels
      WHERE group_id IN (#{namespaces_pending_removal});
      EOF

      execute <<-EOF.strip_heredoc
      DELETE FROM protected_branch_merge_access_levels
      WHERE group_id IN (#{namespaces_pending_removal});
      EOF
    end

    # This removes namespaces that were supposed to be deleted but still reside
    # in the database.
    execute "DELETE FROM namespaces WHERE deleted_at IS NOT NULL;"
  end

  def down
    # This is an irreversible migration;
    # If someone is trying to rollback for other reasons, we should not throw an Exception.
    # raise ActiveRecord::IrreversibleMigration
  end

  def namespaces_pending_removal
    "SELECT id FROM (
      SELECT id
      FROM namespaces
      WHERE deleted_at IS NOT NULL
    ) namespace_ids"
  end
end

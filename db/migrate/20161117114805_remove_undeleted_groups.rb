# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveUndeletedGroups < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute "DELETE FROM namespaces WHERE deleted_at IS NOT NULL;"
  end

  def down
    # This is an irreversible migration;
    # If someone is trying to rollback for other reasons, we should not throw an Exception.
    # raise ActiveRecord::IrreversibleMigration
  end
end

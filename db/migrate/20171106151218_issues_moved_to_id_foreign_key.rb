# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class IssuesMovedToIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'

    def self.with_orphaned_moved_to_issues
      if Gitlab::Database.postgresql?
        # Be careful to use a second table here for comparison otherwise we'll null
        # out all rows that don't have id == moved.to_id!
        where('NOT EXISTS (SELECT true FROM issues B WHERE issues.moved_to_id = B.id)')
          .where('moved_to_id IS NOT NULL')
      else
        # MySQL doesn't allow modification of the same table in a subquery,
        # and using a temporary table isn't automatically guaranteed to work
        # due to the MySQL query optimizer. See
        # https://dev.mysql.com/doc/refman/5.7/en/update.html for more
        # details.
        joins('LEFT JOIN issues AS b ON issues.moved_to_id = b.id')
          .where('issues.moved_to_id IS NOT NULL AND b.id IS NULL')
      end
    end
  end

  def up
    Issue.with_orphaned_moved_to_issues.each_batch(of: 100) do |batch|
      batch.update_all(moved_to_id: nil)
    end

    add_concurrent_foreign_key(
      :issues,
      :issues,
      column: :moved_to_id,
      on_delete: :nullify
    )

    # We're using a partial index here so we only index the data we actually
    # care about.
    add_concurrent_index(:issues, :moved_to_id, where: 'moved_to_id IS NOT NULL')
  end

  def down
    remove_foreign_key_without_error(:issues, column: :moved_to_id)
    remove_concurrent_index(:issues, :moved_to_id)
  end
end

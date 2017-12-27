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
      # Be careful to use a second table here for comparison otherwise we'll null
      # out all rows that don't have id == moved_to_id!
      where('NOT EXISTS (SELECT true FROM issues b WHERE issues.moved_to_id = b.id)')
        .where('moved_to_id IS NOT NULL')
    end
  end

  def up
    if Gitlab::Database.postgresql?
      postgresql_remove_orphaned_moved_to_ids
    else
      mysql_remove_orphaned_moved_to_ids
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

  private

  def postgresql_remove_orphaned_moved_to_ids
    Issue.with_orphaned_moved_to_issues.each_batch(of: 100) do |batch|
      batch.update_all(moved_to_id: nil)
    end
  end

  # MySQL doesn't allow modification of the same table in a subquery. See
  # https://dev.mysql.com/doc/refman/5.7/en/update.html for more details.
  def mysql_remove_orphaned_moved_to_ids
    execute <<~SQL
      UPDATE issues AS a
      LEFT JOIN issues AS b ON a.moved_to_id = b.id
      SET a.moved_to_id = NULL
      WHERE a.moved_to_id IS NOT NULL AND b.id IS NULL;
    SQL
  end
end

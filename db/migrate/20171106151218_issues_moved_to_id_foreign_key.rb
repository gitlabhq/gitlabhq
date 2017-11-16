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
      where('NOT EXISTS (SELECT true FROM issues WHERE issues.id = issues.moved_to_id)')
        .where('moved_to_id IS NOT NULL')
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

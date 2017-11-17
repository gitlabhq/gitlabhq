# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class IssuesUpdatedByIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'

    def self.with_orphaned_updaters
      where('NOT EXISTS (SELECT true FROM users WHERE users.id = issues.updated_by_id)')
        .where('updated_by_id IS NOT NULL')
    end
  end

  def up
    Issue.with_orphaned_updaters.each_batch(of: 100) do |batch|
      batch.update_all(updated_by_id: nil)
    end

    # This index is only used for foreign keys, and those in turn will always
    # specify a value. As such we can add a WHERE condition to make the index
    # smaller.
    add_concurrent_index(:issues, :updated_by_id, where: 'updated_by_id IS NOT NULL')

    add_concurrent_foreign_key(
      :issues,
      :users,
      column: :updated_by_id,
      on_delete: :nullify
    )
  end

  def down
    remove_foreign_key_without_error(:issues, column: :updated_by_id)
    remove_concurrent_index(:issues, :updated_by_id)
  end
end

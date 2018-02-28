# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateRemainingIssuesClosedAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'
    include EachBatch
  end

  def up
    Gitlab::BackgroundMigration.steal('CopyColumn')
    Gitlab::BackgroundMigration.steal('CleanupConcurrentTypeChange')

    # It's possible the cleanup job was killed which means we need to manually
    # migrate any remaining rows.
    migrate_remaining_rows if migrate_column_type?
  end

  def down
  end

  def migrate_remaining_rows
    Issue.where('closed_at_for_type_change IS NULL AND closed_at IS NOT NULL').each_batch do |batch|
      batch.update_all('closed_at_for_type_change = closed_at')
    end

    cleanup_concurrent_column_type_change(:issues, :closed_at)
  end

  def migrate_column_type?
    # Some environments may have already executed the previous version of this
    # migration, thus we don't need to migrate those environments again.
    column_for('issues', 'closed_at').type == :datetime # rubocop:disable Migration/Datetime
  end
end

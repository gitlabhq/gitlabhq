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

    if migrate_column_type?
      if closed_at_for_type_change_exists?
        migrate_remaining_rows
      else
        # Due to some EE merge problems some environments may not have the
        # "closed_at_for_type_change" column. If this is the case we have no
        # other option than to migrate the data _right now_.
        change_column_type_concurrently(:issues, :closed_at, :datetime_with_timezone)
        cleanup_concurrent_column_type_change(:issues, :closed_at)
      end
    end
  end

  def down
    # Previous migrations already revert the changes made here.
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

  def closed_at_for_type_change_exists?
    columns('issues').any? { |col| col.name == 'closed_at_for_type_change' }
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
# rubocop:disable Migration/Datetime
class ScheduleIssuesClosedAtTypeChange < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'
    include EachBatch

    def self.to_migrate
      where('closed_at IS NOT NULL')
    end
  end

  def up
    return unless migrate_column_type?

    change_column_type_using_background_migration(
      Issue.to_migrate,
      :closed_at,
      :datetime_with_timezone
    )
  end

  def down
    return if migrate_column_type?

    change_column_type_using_background_migration(
      Issue.to_migrate,
      :closed_at,
      :datetime
    )
  end

  def migrate_column_type?
    # Some environments may have already executed the previous version of this
    # migration, thus we don't need to migrate those environments again.
    column_for('issues', 'closed_at').type == :datetime
  end
end

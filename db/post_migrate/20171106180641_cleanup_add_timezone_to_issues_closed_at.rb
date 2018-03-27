# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanupAddTimezoneToIssuesClosedAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_type_change(:issues, :closed_at)
  end

  # rubocop:disable Migration/Datetime
  def down
    change_column_type_concurrently(:issues, :closed_at, :datetime)
  end
end

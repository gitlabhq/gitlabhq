# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class SchedulePruneOrphanedGeoEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    BackgroundMigrationWorker.perform_async('PruneOrphanedGeoEvents')
  end

  def down
    # NOOP
  end
end

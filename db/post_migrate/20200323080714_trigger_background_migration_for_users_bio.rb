# frozen_string_literal: true

class TriggerBackgroundMigrationForUsersBio < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 500
  MIGRATION = 'MigrateUsersBioToUserDetails'

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'

    include ::EachBatch
  end

  def up
    relation = User.where("(COALESCE(bio, '') IS DISTINCT FROM '')")

    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end

# # frozen_string_literal: true

class ScheduleUpdateExistingUsersThatRequireTwoFactorAuth < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'UpdateExistingUsersThatRequireTwoFactorAuth'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  INDEX_NAME = 'index_users_on_require_two_factor_authentication_from_group'

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    include EachBatch

    self.table_name = 'users'
  end

  def up
    add_concurrent_index :users,
                         :require_two_factor_authentication_from_group,
                         where: 'require_two_factor_authentication_from_group = TRUE',
                         name: INDEX_NAME

    relation = User.where(require_two_factor_authentication_from_group: true)

    queue_background_migration_jobs_by_range_at_intervals(
      relation, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end

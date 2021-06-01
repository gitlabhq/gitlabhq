# frozen_string_literal: true

class ScheduleUpdateUsersWhereTwoFactorAuthRequiredFromGroup < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'UpdateUsersWhereTwoFactorAuthRequiredFromGroup'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  INDEX_NAME = 'index_users_require_two_factor_authentication_from_group_false'

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    include EachBatch

    self.table_name = 'users'
  end

  def up
    add_concurrent_index :users,
                         :require_two_factor_authentication_from_group,
                         where: 'require_two_factor_authentication_from_group = FALSE',
                         name: INDEX_NAME

    relation = User.where(require_two_factor_authentication_from_group: false)

    queue_background_migration_jobs_by_range_at_intervals(
      relation, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end

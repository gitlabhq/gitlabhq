# frozen_string_literal: true

class MigratePrivateProfileNulls < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY = 5.minutes.to_i
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'

    include ::EachBatch
  end

  def up
    # Migration will take about 7 hours
    User.where(private_profile: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql("MIN(id)"), Arel.sql("MAX(id)")).first
      delay = index * DELAY

      BackgroundMigrationWorker.perform_in(delay.seconds, 'MigrateNullPrivateProfileToFalse', [*range])
    end
  end

  def down
    # noop
  end
end

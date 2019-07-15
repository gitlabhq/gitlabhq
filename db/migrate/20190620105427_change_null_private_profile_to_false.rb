# frozen_string_literal: true

class ChangeNullPrivateProfileToFalse < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY = 30.seconds.to_i
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'

    include ::EachBatch
  end

  def up
    change_column_default :users, :private_profile, false

    # Migration will take about 120 hours
    User.where(private_profile: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(id)', 'MAX(id)').first
      delay = index * DELAY

      BackgroundMigrationWorker.perform_in(delay.seconds, 'MigrateNullPrivateProfileToFalse', [*range])
    end
  end

  def down
    change_column_default :users, :private_profile, nil
  end
end

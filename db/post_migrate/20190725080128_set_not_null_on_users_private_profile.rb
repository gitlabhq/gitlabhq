# frozen_string_literal: true

class SetNotNullOnUsersPrivateProfile < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('MigrateNullPrivateProfileToFalse')

    # rubocop:disable Migration/UpdateLargeTable
    # rubocop:disable Migration/UpdateColumnInBatches
    # Data has been migrated previously, count should be close to 0
    update_column_in_batches(:users, :private_profile, false) do |table, query|
      query.where(table[:private_profile].eq(nil))
    end

    change_column_null :users, :private_profile, false
  end

  def down
    change_column_null :users, :private_profile, true
  end
end

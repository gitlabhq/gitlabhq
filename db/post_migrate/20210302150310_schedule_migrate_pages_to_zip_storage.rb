# frozen_string_literal: true

class ScheduleMigratePagesToZipStorage < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'MigratePagesToZipStorage'
  BATCH_SIZE = 10
  BATCH_TIME = 5.minutes

  disable_ddl_transaction!

  def up
    # no-op
  end
end

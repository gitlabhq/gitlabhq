# frozen_string_literal: true

class UpdateLocationFingerprintForCsFindings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  BATCH_SIZE = 1_000
  INTERVAL = 2.minutes

  # 815_565 records
  def up
    # no-op
    # There was a bug introduced with this migration for gitlab.com
    # We created new migration to mitigate that VERISON=20200907123723
    # and change this one to no-op to prevent running migration twice
  end

  def down
    # no-op
    # intentionally blank
  end
end

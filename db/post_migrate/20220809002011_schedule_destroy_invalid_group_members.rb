# frozen_string_literal: true

class ScheduleDestroyInvalidGroupMembers < Gitlab::Database::Migration[2.0]
  MIGRATION = 'DestroyInvalidGroupMembers'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  MAX_BATCH_SIZE = 2_000
  SUB_BATCH_SIZE = 50

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    # no-op
    # We want to no-op this due to potential inconsistencies in SM upgrade path
  end

  def down
    # no-op
  end
end

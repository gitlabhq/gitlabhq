# frozen_string_literal: true

class ScheduleDestroyInvalidProjectMembers < Gitlab::Database::Migration[2.0]
  MIGRATION = 'DestroyInvalidProjectMembers'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50_000
  MAX_BATCH_SIZE = 100_000
  SUB_BATCH_SIZE = 200

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op
    # We want to no-op this due to potential inconsistencies in SM upgrade path
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class MigrateRedisSlotKeys < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # deleted as contained a bug
  end

  def down
    # no-op
  end
end

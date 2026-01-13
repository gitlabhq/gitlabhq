# frozen_string_literal: true

class AlterCiFinishedBuildsEngine < ClickHouse::Migration
  def up
    # no-op: Previous migration attempt failed due to insufficient privileges
    # to query `system.parts` table. This will be addressed in a follow-up migration.
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class AddRunnerOwnerNamespaceIdToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD COLUMN IF NOT EXISTS runner_owner_namespace_id UInt64 DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP COLUMN IF EXISTS runner_owner_namespace_id
    SQL
  end
end

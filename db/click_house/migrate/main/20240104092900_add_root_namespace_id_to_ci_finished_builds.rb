# frozen_string_literal: true

class AddRootNamespaceIdToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD COLUMN IF NOT EXISTS root_namespace_id UInt64 DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP COLUMN IF EXISTS root_namespace_id
    SQL
  end
end

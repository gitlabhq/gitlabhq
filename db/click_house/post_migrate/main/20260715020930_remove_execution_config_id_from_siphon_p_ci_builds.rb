# frozen_string_literal: true

class RemoveExecutionConfigIdFromSiphonPCiBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_p_ci_builds DROP COLUMN IF EXISTS execution_config_id;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_p_ci_builds ADD COLUMN IF NOT EXISTS execution_config_id Nullable(Int64);
    SQL
  end
end

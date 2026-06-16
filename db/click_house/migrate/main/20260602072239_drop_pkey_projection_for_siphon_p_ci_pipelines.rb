# frozen_string_literal: true

class DropPkeyProjectionForSiphonPCiPipelines < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_p_ci_pipelines DROP PROJECTION IF EXISTS pg_pkey_ordered
      SETTINGS mutations_sync = 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_p_ci_pipelines
        ADD PROJECTION IF NOT EXISTS pg_pkey_ordered
        (
          SELECT *
          ORDER BY
            id,
            partition_id
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_p_ci_pipelines MATERIALIZE PROJECTION pg_pkey_ordered
    SQL
  end
end

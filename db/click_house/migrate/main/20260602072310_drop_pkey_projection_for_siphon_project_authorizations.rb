# frozen_string_literal: true

class DropPkeyProjectionForSiphonProjectAuthorizations < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_project_authorizations DROP PROJECTION IF EXISTS pg_pkey_ordered
      SETTINGS mutations_sync = 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_project_authorizations
        ADD PROJECTION IF NOT EXISTS pg_pkey_ordered
        (
          SELECT *
          ORDER BY
            user_id,
            project_id,
            access_level
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_project_authorizations MATERIALIZE PROJECTION pg_pkey_ordered
    SQL
  end
end

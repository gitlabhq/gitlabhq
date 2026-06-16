# frozen_string_literal: true

class DropPkeyProjectionForSiphonNotes < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_notes DROP PROJECTION IF EXISTS pg_pkey_ordered
      SETTINGS mutations_sync = 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_notes
        ADD PROJECTION IF NOT EXISTS pg_pkey_ordered
        (
          SELECT *
          ORDER BY id
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_notes MATERIALIZE PROJECTION pg_pkey_ordered
    SQL
  end
end

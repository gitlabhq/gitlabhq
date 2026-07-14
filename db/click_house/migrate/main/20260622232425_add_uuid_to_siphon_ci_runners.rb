# frozen_string_literal: true

class AddUuidToSiphonCiRunners < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_ci_runners ADD COLUMN IF NOT EXISTS uuid Nullable(UUID);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_ci_runners DROP COLUMN IF EXISTS uuid;
    SQL
  end
end

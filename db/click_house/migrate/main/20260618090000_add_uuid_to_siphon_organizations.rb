# frozen_string_literal: true

class AddUuidToSiphonOrganizations < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_organizations ADD COLUMN IF NOT EXISTS uuid UUID;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_organizations DROP COLUMN IF EXISTS uuid;
    SQL
  end
end

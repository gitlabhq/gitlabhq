# frozen_string_literal: true

class AddStateToSiphonOrganizations < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_organizations ADD COLUMN state Int16 DEFAULT 0;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_organizations DROP COLUMN state;
    SQL
  end
end

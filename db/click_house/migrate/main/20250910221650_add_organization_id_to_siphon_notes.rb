# frozen_string_literal: true

class AddOrganizationIdToSiphonNotes < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_notes ADD COLUMN organization_id Nullable(Int64);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_notes DROP COLUMN organization_id;
    SQL
  end
end

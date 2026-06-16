# frozen_string_literal: true

class AddScannerExternalIdToSiphonSecurityScans < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_security_scans ADD COLUMN IF NOT EXISTS scanner_external_id Nullable(String);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_security_scans DROP COLUMN IF EXISTS scanner_external_id;
    SQL
  end
end

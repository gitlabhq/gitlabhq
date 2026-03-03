# frozen_string_literal: true

class AddScannerReportedSeverityToSiphonSecurityFindings < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_security_findings ADD COLUMN scanner_reported_severity Int16 DEFAULT 0;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_security_findings DROP COLUMN scanner_reported_severity;
    SQL
  end
end

# frozen_string_literal: true

class AddContextUnawareUuidToSiphonSecurityFindings < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_security_findings ADD COLUMN context_unaware_uuid UUID;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_security_findings DROP COLUMN context_unaware_uuid;
    SQL
  end
end

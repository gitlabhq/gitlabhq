# frozen_string_literal: true

class CreateSharedSequenceForAuditEvents < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    execute <<-SQL
      CREATE SEQUENCE IF NOT EXISTS shared_audit_event_id_seq;
    SQL
  end

  def down
    execute <<-SQL
      DROP SEQUENCE IF EXISTS shared_audit_event_id_seq;
    SQL
  end
end

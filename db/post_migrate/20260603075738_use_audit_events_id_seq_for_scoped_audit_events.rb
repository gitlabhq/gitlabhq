# frozen_string_literal: true

class UseAuditEventsIdSeqForScopedAuditEvents < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  SCOPED_TABLES = %i[group_audit_events instance_audit_events project_audit_events user_audit_events].freeze
  LEGACY_SEQUENCE = 'audit_events_id_seq'
  ORIGINAL_SCOPED_SEQUENCE = 'shared_audit_event_id_seq'

  # The scoped audit event tables default to nextval(shared_audit_event_id_seq),
  # but during dual-write the id is copied from audit_events.id (which uses
  # audit_events_id_seq), so shared_audit_event_id_seq never advances. When
  # stop_legacy_audit_event_writes flips on, the scoped tables would start
  # drawing from a sequence still near 1, colliding with rows already inserted
  # with much larger ids.
  #
  # Repoint the scoped tables at audit_events_id_seq, which is already correctly
  # advanced from years of legacy writes. No setval needed. Detach OWNED BY so
  # the sequence survives the eventual DROP TABLE audit_events.
  def up
    SCOPED_TABLES.each do |table|
      with_lock_retries do
        execute("ALTER TABLE #{table} ALTER COLUMN id SET DEFAULT nextval('#{LEGACY_SEQUENCE}'::regclass)")
      end
    end

    execute("ALTER SEQUENCE #{LEGACY_SEQUENCE} OWNED BY NONE")
  end

  def down
    execute("ALTER SEQUENCE #{LEGACY_SEQUENCE} OWNED BY audit_events.id")

    SCOPED_TABLES.each do |table|
      with_lock_retries do
        execute("ALTER TABLE #{table} ALTER COLUMN id SET DEFAULT nextval('#{ORIGINAL_SCOPED_SEQUENCE}'::regclass)")
      end
    end
  end
end

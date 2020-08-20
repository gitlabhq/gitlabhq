# frozen_string_literal: true

class RemoveNotNullConstraintOnTypeFromAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # To avoid deadlock on audit_event and audit_event_part... since there is a trigger to insert record from audit_events
  # to audit_events_part..., we need to ensure each ALTER TABLE command run in its own transaction.
  def up
    with_lock_retries do
      change_column_null :audit_events_part_5fc467ac26, :type, true
    end

    with_lock_retries do
      change_column_null :audit_events, :type, true
    end
  end

  def down
    # no-op -- null values might be added after this constraint is removed.
  end
end

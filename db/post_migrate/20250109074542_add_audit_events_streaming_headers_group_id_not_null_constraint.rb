# frozen_string_literal: true

class AddAuditEventsStreamingHeadersGroupIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :audit_events_streaming_headers, :group_id
  end

  def down
    remove_not_null_constraint :audit_events_streaming_headers, :group_id
  end
end
